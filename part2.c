/* This files provides address values that exist in the system */

#define SDRAM_BASE            0xC0000000
#define FPGA_ONCHIP_BASE      0xC8000000
#define FPGA_CHAR_BASE        0xC9000000

/* Cyclone V FPGA devices */
#define LEDR_BASE             0xFF200000
#define HEX3_HEX0_BASE        0xFF200020
#define HEX5_HEX4_BASE        0xFF200030
#define SW_BASE               0xFF200040
#define KEY_BASE              0xFF200050
#define TIMER_BASE            0xFF202000
#define PIXEL_BUF_CTRL_BASE   0xFF203020
#define CHAR_BUF_CTRL_BASE    0xFF203030

/* VGA colors */
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
#define RED 0xF800
#define GREEN 0x07E0
#define BLUE 0x001F
#define CYAN 0x07FF
#define MAGENTA 0xF81F
#define GREY 0xC618
#define PINK 0xFC18
#define ORANGE 0xFC00
#define BLACK 0x0000


#define ABS(x) (((x) > 0) ? (x) : -(x))

/* Screen size. */
#define RESOLUTION_X 320
#define RESOLUTION_Y 240

/* Constants for animation */
#define BOX_LEN 2
#define NUM_BOXES 8

#define FALSE 0
#define TRUE 1

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
	
#include <unistd.h>

// Begin part1.s for Lab 7

volatile int pixel_buffer_start; // global variable
void draw_line(int x0, int x1, int y0, int y1, short int colour);
void swap(int *a, int *b);
void clear_screen(void);
void plot_pixel(int x, int y, short int line_color);
void wait_for_vsync(void);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

	//start with black screen 
    clear_screen();
	
	//line spans across x 
	int x0 = 0;
	int x1 = 319;
	//line goes from top to bottom of screen
	int y0 = 0;
	int y1 = 0;
	
	//value to increment Y by, either move up or down depending on where line is on screen
	int incrementY = 0;
	
	while(1){
		//draw a white line
		draw_line(x0, y0, x1, y1, WHITE);
		//wait
		wait_for_vsync();
		//clear screen
		draw_line(x0, y0, x1, y1, BLACK);
		
		//at top of screen
		if(y0 == 0){
			incrementY = 1;
		}
		//at bottom of screen
		else if(y1 == 239){
			incrementY = -1;
		}
		
		y0 += incrementY;
		y1 += incrementY; 
		
	}

}

//function that renders cycle, given in lecture 19
void wait_for_vsync(){
	//address of front buffer address register
	volatile int *pixel_ctrl_ptr = (int *) 0xff203020;
	int status;
	
	//sets the s bit of the status register
	*pixel_ctrl_ptr = 1;
	
	//poll the status bit
	status = *(pixel_ctrl_ptr +3);
	//isolate rightmost bit in status register
	while((status & 0x01) != 0){
		status = *(pixel_ctrl_ptr + 3);
	}
	
	//exit
	return; 
	
}

void draw_line(int x0, int y0, int x1, int y1, short int colour) {
	int is_steep = ABS(y1 - y0) > ABS(x1-x0);
	
	if(is_steep){
		//swap x0, y0
		swap(&x0, &y0);
		swap(&x1, &y1);
	}
	if(x0 > x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
		
	}
	
	int deltax = x1-x0;
	int deltay = ABS(y1-y0); 
	int error = -(deltax/2);
	
	int y = y0;
	int y_step = -1;
	if(y0 < y1){
		y_step = 1;
	}
	
	int x = x0;
	for(x=x0; x <= x1; x++){
		if(is_steep){
			plot_pixel(y, x, colour);
		}
		else{
			plot_pixel(x, y, colour);
		}
		error += deltay;
		if(error >= 0){
			 y += y_step;
			 error -=  deltax;
		}
	}	
}

//helper function, swaps two variables
void swap(int *a, int *b){
	int temp = *a;
	*a = *b;
	*b = temp;
}

//write black into entire screen, blank every pixel
void clear_screen(void){
	int i = 0; //for x coordinates in screen
	int j = 0; //for y coordinates in screen
	for(i=0; i < 320; i++){
		for(j=0; j < 240; j++){
			plot_pixel(i, j, BLACK);  //sets every pixel to black
		}
	}
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

	