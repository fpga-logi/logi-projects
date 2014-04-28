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

#define LINE_BURST 2

#define FIFO_CMD_ADDR 0x0200

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
