/* Program that finds the largest number in a list of integers	*/
            
            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
            STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the list
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list */
LARGE:      MOV R2,R0  //R2 holds the numbers of entries
			MOV R3, R1   //R3 points to the start of the list
			LDR R0,[R3] //R0 holds the largest number so far
LOOP:		SUBS R2, #1  //decrement the loop counter
			BEQ	DONE   //if loop counter equals zero, branch
			add R3, #4 //move to the address of the next number in the number list
			LDR R5, [R3] //load the next number into R5
			CMP R0, R5 //check if larger number found
			BGE	LOOP	//if R0 is greater than R5, move to the next number 
			MOV R0, R5//else copy the larger number into R0 from R5
			B LOOP   //branch back to loop
DONE:		MOV PC,LR
			MOV R5, #0
			
RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            
