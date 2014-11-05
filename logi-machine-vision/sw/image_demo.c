#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <time.h>
#include <linux/ioctl.h>

#include "jpeg_func.h"
#include "logilib.h"

#define IMAGE_WIDTH 320
#define IMAGE_HEIGHT 240

#define LINE_BURST 1

#define REG_ADDR 0x0800
#define FIFO_CMD_ADDR 0x0200


#define GAUSS_SOURCE_FIFO 0
#define GAUSS_SOURCE_SOBEL 1
#define GAUSS_SOURCE_ERODE 2
#define GAUSS_SOURCE_DILATE 3
#define GAUSS_SOURCE_HYST 4

#define SOBEL_SOURCE_FIFO 0
#define SOBEL_SOURCE_GAUSS 1
#define SOBEL_SOURCE_ERODE 2
#define SOBEL_SOURCE_DILATE 3
#define SOBEL_SOURCE_HYST 4

#define ERODE_SOURCE_FIFO 0
#define ERODE_SOURCE_GAUSS 1
#define ERODE_SOURCE_SOBEL 2
#define ERODE_SOURCE_DILATE 3
#define ERODE_SOURCE_HYST 4

#define DILATE_SOURCE_FIFO 0
#define DILATE_SOURCE_GAUSS 1
#define DILATE_SOURCE_SOBEL 2
#define DILATE_SOURCE_ERODE 3
#define DILATE_SOURCE_HYST 4

#define HYST_SOURCE_FIFO 0
#define HYST_SOURCE_GAUSS 1
#define HYST_SOURCE_SOBEL 2
#define HYST_SOURCE_ERODE 3
#define HYST_SOURCE_DILATE 4

#define OUTPUT_SOURCE_FIFO 0
#define OUTPUT_SOURCE_GAUSS 1
#define OUTPUT_SOURCE_SOBEL 2
#define OUTPUT_SOURCE_ERODE 3
#define OUTPUT_SOURCE_DILATE 4
#define OUTPUT_SOURCE_HYST 5


int min(int a, int b){
	if(a > b ){
		return b ;	
	}
	return a ;
}

int main(int argc, char ** argv){
	unsigned char * inputImage ;
	long start_time, end_time ;
	double diff_time ;
	struct timespec cpu_time ;
	FILE * jpeg_fd ;
	FILE * raw_file ;
	int i,j, res ;
	unsigned int pos = 0 ;
	unsigned short int cmd_buffer[4];
	unsigned short int reg_buffer[6];
	unsigned char image_buffer[(320*240)] ; //monochrome frame buffer
	unsigned short fifo_state, fifo_data ;
	if(logi_open() < 0){
		printf("Error openinglogi \n");
		return -1 ;	
	}
	jpeg_fd  = fopen("./grabbed_frame.jpg", "w");
	if(jpeg_fd == NULL){
		perror("Error opening output file");
		exit(EXIT_FAILURE);
	}
	printf("output file openened \n");
	printf("loading input file : %s \n", argv[1]);
	res = read_jpeg_file( argv[1], &inputImage);
	if(res < 0){
		perror("Error opening input file");
		exit(EXIT_FAILURE);
	}
	
	//configuring for gauss->sobel->hysteresis->dilate->erode->output
	reg_buffer[0] = GAUSS_SOURCE_FIFO ;
	reg_buffer[1] = SOBEL_SOURCE_GAUSS ;
	reg_buffer[2] = ERODE_SOURCE_DILATE ;
	reg_buffer[3] = DILATE_SOURCE_HYST ;
	reg_buffer[4] = HYST_SOURCE_SOBEL ;
	reg_buffer[5] = OUTPUT_SOURCE_ERODE ;
	logi_write(reg_buffer, 12, REG_ADDR);
	printf("issuing reset to fifo \n");
	cmd_buffer[1] = 0; 
	cmd_buffer[2] = 0 ;
	logi_write(cmd_buffer, 6, FIFO_CMD_ADDR);
	logi_read(cmd_buffer, 6, FIFO_CMD_ADDR);
	printf("fifo size : %d, free: %d, available : %d \n", cmd_buffer[0],cmd_buffer[1], cmd_buffer[2]);
	clock_gettime(CLOCK_REALTIME, &cpu_time);
	start_time = cpu_time.tv_nsec ;
	 for(i = 0 ; i < IMAGE_HEIGHT ; i +=LINE_BURST){
		logi_write(&inputImage[(i*IMAGE_WIDTH)], IMAGE_WIDTH*LINE_BURST, 0x0000);
		do{
			logi_read(cmd_buffer, 6, FIFO_CMD_ADDR);
			//printf("fifo size : %d, free: %d, available : %d \n", cmd_buffer[0],cmd_buffer[1], cmd_buffer[2]);
		}while((cmd_buffer[2]*2) < IMAGE_WIDTH*LINE_BURST);
		logi_read(&image_buffer[(i*IMAGE_WIDTH)], IMAGE_WIDTH*LINE_BURST, 0x0000);
        }
	clock_gettime(CLOCK_REALTIME, &cpu_time);
	end_time = cpu_time.tv_nsec ;
	diff_time = end_time - start_time ;
	diff_time = diff_time/1000000000 ;
	printf("transffered %d bytes in %f s : %f B/s \n", IMAGE_WIDTH * IMAGE_HEIGHT, diff_time, (IMAGE_WIDTH * IMAGE_HEIGHT)/diff_time);
	write_jpegfile(image_buffer, 320, 240, jpeg_fd, 100);
	logi_close();
	fclose(jpeg_fd);
	return 0 ;
}
