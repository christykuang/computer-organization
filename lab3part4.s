.global _start
.equ keys,0xFF200050
.equ HEX3_0,0xFF200020
.equ timer, 0xFFFEC600
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment
			
_start:
	LDR R0, =keys //R0 takes the address of keys
	ADD R0, #12   //R0 has the address of edge capture register
	LDR R4, =HEX3_0
	MOV R5, #BIT_CODES
	mov r6,#0 //hex1
	mov r3,#0 //hex0
	mov r10,#0//hex2
	mov r12,#0//hex3
	     //starts with 00 r3=0, r6=0
display: ldrb r7,[r5,r6] //needs the previous r6 value so stay
		 lsl r7,#8  //r7 holds the binary bits for the hundreds digit
		 
		 ldrb r8,[r5,r3] //needs the previous r3 value
			 				//r8 holds the binary bits for the tens digit
		 orr r8,r7 //combine hex0,hex1
		 
		 mov r7,#0 //clear r7
		 ldrb r7,[r5,r10] //r7 has the hex2 binary bit
		 lsl r7,#16 //shift to hex2 location
		 orr r8,r7 //combine hex0,1,2
		 
		 mov r7,#0 //clear r7
		 ldrb r7,[r5,r12] //r7 has the hex3 binary bit
		 lsl r7,#24 //shift to hex3 location
		 orr r8,r7 //combine hex0,1,2,3
		 
		 str r8, [r4] //store into hex display


timer_setup: ldr r2, =timer //base address of a9 private timer
            ldr r11,=2000000
			str r11, [r2]//loaded with 2M ->0.01sec count down
			mov r11,#0b011 //turn on A and E bits in counter control register
			str r11, [r2,#8]
			
//count for 0.25s interval
//poll the timer to wait until 0.25sec has passed
wait: ldr r11,[r2,#0xc] //get the full status register
      ands r11, #0x1 //isolate bit 0
	  beq wait //wait until F bit in interrupt is 1
	           //counter reaches 0
	  str r11, [r2,#0xc] //arrives here while F bit=0, reset F bit
	  b poll
	

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
			 cmp r6, #9  //if hex1 is greater than 9
			 addgt r10,#1 //r10 tracks hex2,hex2=hex2+1
			 cmp r10,#9 //if hex2>9
			 addgt r12,#1 // r12 tracks hex3,hex3=hex3+1
			 cmp r3,#9  //if tens digit hits 9
			 movgt r3,#0 //tens digit goes back to 0
			 cmp r6,#9  //check if hundred digit hits 9
			 movgt r6,#0 //hundreds digit back to zero
			 cmp r10,#9 //if hex2>9
			 movgt r10,#0 //back to zero while hex2>9
			 cmp r12,#5
			 movgt r12,#0
			 b display