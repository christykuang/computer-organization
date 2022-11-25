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
#define N 8
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
// Begin part3.c code for Lab 7

void clear_screen(void);
volatile int pixel_buffer_start; // global variable
void wait_for_vsync(void);
void draw_line(int x0, int x1, int y0, int y1, short int colour);
void swap(int *a, int *b);
void plot_pixel(int x, int y, short int line_color);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer
	
	//the location of each box
	int x_box[N]; 
	int y_box[N];
	//the colour of each box
	short int colour_box[N];
	short int random_colour [10] ={YELLOW,RED,GREEN,BLUE,CYAN,GREY,PINK,ORANGE, MAGENTA,BLACK};
	//the direction of rotation of each box
	int dx[N];
	int dy[N];
	//x is from 0 to 319; y is from 0 to 239
	//create random initial location, colour, direction for the box
	int i;
	for(i=0; i<N; i++){
		x_box[i]=(rand()%319); //0-238 accomodate for the 2x2 pixels 
		y_box[i]=(rand()%239);
		dx[i]=((rand()%2)*2)-1;
		dy[i]=((rand()%2)*2)-1;
		colour_box[i]=random_colour[(rand()%10)];
	}
	
	
    while (1)
    {	
		 /* Erase any boxes and lines that were drawn in the last iteration */
       	clear_screen();
        // code for drawing the boxes and lines (not shown)
		int i,j,a,b;
		for(i=0; i<N;i++){ //draw 8 boxes of size 2x2 pixels
			for(a=0;a<2;a++){
				for(b=0;b<2;b++){
				plot_pixel(x_box[i]+a, y_box[i]+b,colour_box[i]);
				}
			}	
		
		//connecting the points, draw lines
			if(i<(N-1)){
				j=i+1;
			}
			else{
				j=0; //connect the last point back to the first point
			}
			draw_line(x_box[i], y_box[i], x_box[j], y_box[j], random_colour[i]);	
		//check for movements out of bound
		if(x_box[i]==0&&dx[i]==-1)
			dx[i]=1;
		if(y_box[i]==0&&dy[i]==-1)
			dy[i]=1;
		if(x_box[i]==318&&dx[i]==1)
			dx[i]=-1;
		if(y_box[i]==238&&dy[i]==1)
			dy[i]=-1;
			
		x_box[i]+=dx[i];
		y_box[i]+=dy[i];
			
	}
	
		// code for updating the locations of boxes (not show)
		
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }
}

// code for subroutines (not shown)
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
			plot_pixel(i, j, BLACK);  //sets every pixel to white
		}
	}
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

	
