          .text                   // executable code follows
          .global _start                  
_start:  
			MOV		R4, #TEST_NUM //load address OF TEST_NUM into R4
			LDR 	R1, [R4] //load what's at R4 into R1, R1 has first word
			
			MOV 	R0, #0 //R0 is temporary counter for each word
			MOV 	R5, #0 //R5 holds result

//subroutine to count number of 1s in each word
ONES:       CMP 	R1, #0 //loop until the data contains no more 1's	
			BEQ 	NEXTNUM	//if word done, go to next word
			LSR 	R2, R1, #1 //perform SHIFT, followed by AND
			AND		R1, R1, R2
			ADD 	R0, #1 //update temp counter for current word
			B		ONES

//load next word in 
NEXTNUM: 	CMP 	R5, R0 //if R5 perm counter is less than R0, update it
			MOVLT	R5, R0 	
			ADD		R4, #4 //increment address to next word
			MOV 	R0, #0 //reset temp counter
			LDR  	R1, [R4] //load into R1 what's at R4
			CMP 	R1, #0 //check if R1 is 0, if so, terminate
			BEQ 	END
			B 		ONES  //if not, go back to ones loop


END: 		B		END

TEST_NUM: .word 0x00f //4 1's binary: 1111
		  .word 0x103fe00f //9 1's binary: 00010000001111111110000000001111
		  .word 0x0000ffff //16 1's binary: 1111111111111111
		  .word 0x001 //1 1's binary: 1
		  .word 0xff00 //8 1's binary: 1111111100000000
		  .word 0xfff00 //12 1's binary: 11111111111100000000
		  .word 0x1000e13 //3 1's binary: 0001000000000000111000010011
		  .word 0xe3c2 //4 1's binary: 1110001111000010
		  .word 0x0b42  //2 1's binary: 101101000010
		  .word 0x12301 //2 1's binary: 00010010001100000001
		  .word 0x0 //terminate
	
	