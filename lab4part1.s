               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000
/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector
                .word    0                  // FIQ interrupt vector
				

/*********************************************************************************
 * Main program
 ********************************************************************************/
                .text
                .global  _start
				

_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                msr		cpsr_c, #0b11010010 			// interrupts masked (off), MODE = IRQ
				ldr		sp, =0x20000           			// set IRQ stack pointer
				
				msr		cpsr_c, #0b11010011			// interrupts masked, MODE = Supervisor (SVC)								
				ldr		sp, =0x40000				// set supervisor mode (SVC) stack 


                BL       CONFIG_GIC              // configure the ARM generic interrupt controller

                // Configure the KEY pushbutton port to generate interrupts
                ldr r0, =0xff200050  //keys parallel port base address
				mov r1, #0xf //set interreuptmask bits 1111
				str r1, [r0,#8] //offset by 8 from base address

                // enable IRQ interrupts in the processor
                msr cpsr_c,#0b01010011   //processor accepts the interrupt, mode=svc
				
				//set up value of bit code 
				
				
IDLE:
                B        IDLE                    // main program simply idles

IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID

CHECK_KEYS:
                CMP      R5, #73
UNEXPECTED:     BNE      UNEXPECTED              // if not recognized, stop here
    
                BL       KEY_ISR
EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4

/*****************************************************0xFF200050***********************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY(s) have been pressed. It writes to HEX3-0
 ***************************************************************************************/
               

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment	
			
KEY_ISR:      PUSH     {R4-R12, LR}
			   ldr r6,=0xFF200020
			   ldr r10,[r6]  //check if hex display on
			   cmp r10, #0
			   bne OFF //its on, turn off
			   beq ON  //its off, turn on
OFF:         
			  ldr r0,=0xff200050 //base address of key port
			  ldr r3, [r0,#0xc] //get the edge capture register
			   cmp r3,   #1  //key0
	  		   beq key_0
	  		   cmp r3,   #2  //key1
	  		   beq key_1
	 		   cmp r3,   #4  //key2
			   beq key_2
	 	       cmp r3,   #8  //key3
			   beq key_3
		  
key_0: mov r7,#0b00111111 //bit code of 0
        lsl r7,#0
		eor r10, r7
		b next
key_1: mov r7,#0b00000110 //bit code of 1
		lsl r7,#8
		eor r10, r7
        b next
key_2: mov r7, #0b01011011 // bit code of 2
		lsl r7,#16
 		eor r10, r7
        b next
key_3: mov r7, #0b01001111// bit code of 3
        lsl r7, #24
		eor r10, r7
        b next
next:              str r10, [r6]
			  
			  mov r2,#0
			  //turn off the interrupt coming from the key parallel port
			  mov r2,#0xf //1111
			  str r2,[r0,#0xc] //reset edge capture register
			  pop     {R4-R12, LR}
			  MOV      PC, LR
			  
				//ON 
ON:			  ldr r0,=0xff200050 //base address of key port
			   ldr r3, [r0,#0xc] //get the edge capture register
			   
			   cmp r3,   #1  //key0
	  		   moveq r1, #0
	  		   cmp r3,   #2  //key1
	  		   moveq r1, #1
	 		   cmp r3,   #4  //key2
			   moveq r1, #2
	 	       cmp r3,   #8  //key3
			   moveq r1, #3
			
			  
			   ldr r9,=BIT_CODES
			   ldr r2, =0xFF200020  //address of hex display 
			   ldrb r9, [r9,r1]
		       
			   cmp r1,   #0  //key0
	  	       beq key0
	  		   cmp r1,   #1  //key1
	  		   beq key1
	 		   cmp r1,   #2  //key2
			   beq key2
	 	       cmp r1,   #3  //key3
			   beq key3
			   
store:		  str r9, [r2]   //store binary bits in to hex display
				mov r2,#0
				//turn off the interrupt coming from the key parallel port
				mov r2,#0xf //1111
				str r2,[r0,#0xc] //reset edge capture register
				pop     {R4-R12, LR}
                MOV      PC, LR
key0:lsl r9,#0
      b store
key1: lsl r9, #8
      b store
key2: lsl r9, #16
      b store
key3: lsl r9, #24
      b store 	  

				

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable the KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}

                .end 
				
				







