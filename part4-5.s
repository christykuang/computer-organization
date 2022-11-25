          .text                   // executable code follows
          .global _start                  
_start:  
			MOV		R4, #TEST_NUM //load address OF TEST_NUM into R4
			LDR 	R1, [R4] //load what's at R4 into R1, R1 has first word
			MVN 	R3, R1 //R3 has version with flipped bits of R1, bitwise logic not 
			MOV 	R9, R1 //R9 has original input R1
			MOV 	R2, #ALTERNATE //R2 is temp register used for XOR'ing
			LDR		R2, [R2] 
			EOR		R9, R9, R2 //R9 has version XOR'ed with original input R1
			
			MOV 	R2, #0 //reset R2 to 0 for use later
			MOV 	R0, #0 
			MOV 	R5, #0 //R5 holds result
			MOV 	R12, #0 //R7 used for shifting in zeroes loop
			MOV		R8, #0 //R8 is temp counter for zeroes loop
			MOV 	R10, #0 //R10 used for shifting in alternating loop
			MOV		R11, #0 //R11 used for temp counter in alternating loop
			
//subroutine to count number of 1s in each word
ONES:       CMP 	R1, #0 //loop until the data contains no more 1's	
			BEQ 	ZEROES	//if word done, repeat but count 0s
			LSR 	R2, R1, #1 //perform SHIFT, followed by AND
			AND		R1, R1, R2
			ADD 	R0, #1 //update temp counter for current word
			B		ONES
//temp counter for zeroes is R8
//subroutine to find longest string of 0s, using mvn to flip bits and then count 1s
ZEROES:		CMP 	R3, #0
			BEQ 	LOOP
			LSR		R12, R3, #1
			AND     R3, R3, R12
			ADD		R8, #1	
			B		ZEROES

//subroutine to find alternating 1s and 0s, using EORS will get longest sequence of 1s to be counted
LOOP:		MOV     R12, R9 //copy of XORed with 0101 word 
ALTERNATING:CMP 	R9, #0 
			BEQ 	CHANGE
			LSR		R10, R9, #1
			AND		R9, R9, R10
			ADD		R11, #1
			B		ALTERNATING

CHANGE:	 	MOV     R1, R11
			MVN   	R12,R12 //flip bits of R12
			MOV  	R9, R12 //move the flip R12 into R9
			MOV     R11,#0 //CLEAR THE PREVIOUS R1 BEFORE COUNTING AGAIN
			//logic shift right and and bitwise to count for consectuive 1's
COUNTONES:	CMP 	R9, #0 
			BEQ 	NEXTNUM
			LSR		R10, R9, #1
			AND		R9, R9, R10
			ADD		R11, #1
			B		COUNTONES
				
				

				
//load next word in 
NEXTNUM: 	CMP     R11, R1
			MOVLT   R11, R1 //copy R1 into R11 if less than
			CMP 	R5, R0 //if R5 perm counter is less than R0, update it
			MOVLT	R5, R0 	
			CMP		R6, R8
			MOVLT	R6, R8 //if R6 perm counter is less than R8 temp counter, update it 
			CMP 	R7, R11 
			MOVLT	R7, R11 //if R7 perm counter is less than R11 temp counter, update it
			ADD		R4, #4 //increment address to next word
			MOV 	R0, #0 //reset temp counter for ones R0
			MOV		R8, #0 //reset temp counter for zeroes R8
			MOV 	R11, #0 //reset temp counter for alternating R11
			LDR  	R1, [R4] //load into R1 what's at R4
			MVN		R3, R1 //load into R3 the flipped version of R1
			MOV 	R9, R1 //load into R9 what's at R1 (word for this iteration)
			MOV 	R2, #ALTERNATE
			LDR 	R2, [R2]
			EOR 	R9, R9, R2 //load into R9 the XOR'ed version of R1
			MOV		R2, #0 //reset R2 as it's used in ONES loop
			CMP 	R1, #0 //check if R1 is 0, if so, terminate
			BEQ 	RESETREGISTERS //cleans up registers to prevent clobbering
			B 		ONES  //if not, go back to ones loop

RESETREGISTERS: 
			MOV 	R3, #0
			MOV 	R4, #0
			MOV 	R9, #0
			MOV 	R10, #0
			MOV 	R12, #0
			B 		DISPLAY

TEST_NUM: .word 0x0000ffff //16 1's, 16 0's binary: 00000000000000001111111111111111
		  .word 0x00000fff //12 1's, 20 0's binary: 00000000000000000000111111111111
		  .word 0x00005555 //1 1's, 16 0's, 16 alternating binary: 00000000000000000101010101010101
		  .word 0x0
ALTERNATE: .word 0x55555555 //pattern of alternating 1s and 0s

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
			


			
/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */

DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10  //compare the parameter from R0 with the divisor R1
            BLT    DIV_END  
            SUB    R0, #10  
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR		// ones digit will be in R0; tens
                                // digit in R1
								
								


								
/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code for ones digit
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       //r0 contains the bit code for tens digit
            LSL     R0, #8         //logic shift left by 8 for tens digit 
            ORR     R4, R0         //R4's bit 0-6 has ones digit bit code
								//R0's bit 8-14 has tens digit bit code 
      //code for register R6
            MOV		R0, R6
			BL      DIVIDE    //sets the ones(R0) and tens(R1) digit ready for r6
			
			                         
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R11, R0          // save bit code for ones digit in R11
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       //r0 contains the bit code for tens digit
            LSL     R0, #24         //logic shift left by 24 for R6's tens digit 
			LSL     R11, #16        //logic shift left by 16 for R6's ones digit
			ORR     R0, R11         //R0 gets RO or R11 
            ORR     R4, R0         //R4's bit 0-6 has R5 ones digit bit code
								//R4's bit 8-14 has R5 tens digit bit code 
								//R4's bit 16-22 has R6 ones digit bit code
								//R4's bit 24-30 has R6 tens digit bit code 
								
	// display the numbers from R6 and R5					
            STR     R4, [R8]  
			MOV     R4,#0 //clear R4
	//code for register r7		
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
			MOV     R0, R7          // display R7 on HEX5-4
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code for ones digit
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       //r0 contains the bit code for tens digit
            LSL     R0, #8         //logic shift left by 8 for tens digit 
            ORR     R4, R0         //R4's bit 0-6 has ones digit bit code
								//R0's bit 8-14 has tens digit bit code 
     		
            STR     R4, [R8]        // display the number from R7
END: 	   B		END
			