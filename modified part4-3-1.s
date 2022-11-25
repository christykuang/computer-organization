           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // parameter for DIVIDE goes in R0

COMPARE: 	CMP 	R0, #1000       //R0 has the original parameter at the beginning 
			BGE 	SET_4digit
			CMP 	R0 ,#100
			BGE 	SET_3digit
			CMP 	R0 ,#10
			BGE 	SET_2digit
			CMP 	R0,#10    //while the parameter is one digit
			BLT		SET_1digit    //less than ten
			
			
SET_4digit:	MOV R1, #1000      //set divisor to 1000 while it has four digits
			BL     DIVIDE
			STRB   R1, [R5, #3] // Thousands digit is now in R1
			B COMPARE           //remainder is stored at R0 compare again
			
SET_3digit:	MOV R1, #100      //set divisor to 100 when it has three digits
			BL     DIVIDE
			STRB   R1, [R5, #2] // Hundreds digit is now in R1
			B COMPARE		//remainder is stored at R0 compare again
			
SET_2digit:	MOV R1, #10     //set divisor to 10 when it has two digits
			BL DIVIDE
			STRB   R1, [R5, #1] // Tens digit is now in R1
			
SET_1digit: STRB   R0, [R5]     // Ones digit is in R0, one digit will remain in the remainder and no divisor

END:        B      END			
/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */

DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, R1  //compare the parameter from R0 with the divisor R1
            BLT    DIV_END  
            SUB    R0, R1  
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

N:          .word  9876  // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
