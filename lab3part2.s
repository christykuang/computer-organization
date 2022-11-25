.global _start
.equ keys,0xFF200050
.equ HEX10,0xFF200020

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
			
_start:
	LDR R0, =keys //R0 takes the address of keys
	ADD R0, #12   //R0 has the address of edge capture register
	LDR R4, =HEX10
	MOV R5, #BIT_CODES
	mov r6,#0
	mov r3,#0
	LDR R10, =keys //R0 takes the address of keys
	
	     //starts with 00 r3=0, r6=0
display: ldrb r7,[r5,r6] //needs the previous r6 value so stay
		 lsl r7,#8  //r7 holds the binary bits for the hundreds digit
		 ldrb r8,[r5,r3] //needs the previous r3 value
			 				//r8 holds the binary bits for the tens digit
		 orr r8,r7
		 str r8, [r4]
		 
//count for 0.25s interval
DO_DELAY: LDR R7, =500000
SUB_LOOP: SUBS R7,R7,#1
		  BNE SUB_LOOP
		  b poll //check if next key is pressed 
	

poll: ldr r1, [r0] //loads the edge capture register 
	  cmp r1,#0 //compare edge capture register to 0
	  beq hex_display //if no key pressed, add number 
	  
	  //if a key is pressed, stop 
	  //something done to the hex display
	  //stop/ start the hex display 
	  //reset edge capture register 
	  cmp r1,   #1  //key0
	  moveq r9, #1
	  cmp r1,   #2  //key1
	  moveq r9, #2
	  cmp r1,   #4  //key2
	  moveq r9, #4
	  cmp r1,   #8  //key3
	  moveq r9, #8
      
	  str r9, [r0] //by writing a 1 into that bit of edge capture register
	  
	  //wait for next press to start again
	  //check edge register again
load: ldr r1, [r0] //loads the edge capture register 
	  cmp r1, #0 //compare edge capture register value to 0
	  bne hex_display //not equal 1, a key pressed, start again
	  b load  //no key pressed, stay here loop
	  
	  
	  
hex_display: cmp r1,   #1 //reset edge register after a stop&start
	  		 moveq r9, #1
	  		 cmp r1,   #2
	  		 moveq r9, #2
	  		 cmp r1,   #4
	  		 moveq r9, #4
	  		 cmp r1,   #8
	  		 moveq r9, #8
	  		 str r9, [r0] //by writing a 1 into that bit of edge capture register
			 add r3,#1 //increment by one
			 cmp r3,#9 //if tens digit hits 9
			 addgt r6, #1 //hundreds digit goes up by 1
			 cmp r3,#9  //if tens digit hits 9
			 movgt r3,#0 //tens digit goes back to 0
			 cmp r6,#9   //check if hundred digit hits 9
			 movgt r3,#0 //tens digit back to 0
			 cmp r6,#9  //check if hundred digit hits 9
			 movgt r6,#0 //hundreds digit back to zero
			 
			 b display