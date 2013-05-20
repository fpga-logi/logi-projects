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
#include <math.h>

#include "jpeg_func.h"
#include "fifolib.h"

#define IMAGE_WIDTH 160
#define IMAGE_HEIGHT 120


char rgb_file_name [128] ;
char yuv_file_name [128] ;

int min(int a, int b){
	if(a > b ){
		return b ;	
	}
	return a ;
}

int main(int argc, char ** argv){
	long start_time, end_time ;
	double diff_time ;
	struct timespec cpu_time ;
	unsigned short vsync1, vsync2 ;
	FILE * rgb_fd, * yuv_fd ;
	int i,j, res, inc = 0;
	unsigned int nbFrames = 1 ;
	unsigned int pos = 0 ;
	unsigned char * image_buffer, * start_buffer, * end_ptr; //yuv frame buffer
	unsigned char * rgb_buffer ;
	unsigned short fifo_state, fifo_data ;
	float y, u, v ;
	float r, g, b ;
	if(argc > 1){
		nbFrames = atoi(argv[1]);
	}
	if(fifo_open(1) < 0 || image_buffer == 0){
                        printf("Error opening fifo 0 \n");
                        return -1 ;     
        }
	image_buffer = (unsigned char *) malloc(IMAGE_WIDTH*IMAGE_HEIGHT*3);
	for(inc = 0 ; inc < nbFrames ; ){
		sprintf(yuv_file_name, "./grabbed_frame%04d.jpg", inc);
		yuv_fd  = fopen(yuv_file_name, "w");
		if(yuv_fd == NULL){
			perror("Error opening output file");
			exit(EXIT_FAILURE);
		}
		//fifo_reset(1);
		clock_gettime(CLOCK_REALTIME, &cpu_time);
		start_time = cpu_time.tv_nsec ;
		fifo_reset(1);
		fifo_read(1, image_buffer, IMAGE_WIDTH*IMAGE_HEIGHT*3);
		clock_gettime(CLOCK_REALTIME, &cpu_time);
		end_time = cpu_time.tv_nsec ;
		diff_time = end_time - start_time ;
		diff_time = diff_time/1000000000 ;
		printf("transffered %d bytes in %f s : %f B/s \n", (IMAGE_WIDTH * IMAGE_HEIGHT*3), diff_time, (IMAGE_WIDTH * IMAGE_HEIGHT*3)/diff_time);
		start_buffer = image_buffer ;
		end_ptr = &image_buffer[IMAGE_WIDTH*IMAGE_HEIGHT*3];
		vsync1 = *((unsigned short *) start_buffer) ;
		vsync2 = *((unsigned short *) &start_buffer[(IMAGE_WIDTH*IMAGE_HEIGHT)+2]) ;
		while(vsync1 != 0x55AA && vsync2 != 0x55AA && start_buffer < end_ptr){
			start_buffer+=2 ;
			vsync1 = *((unsigned short *) start_buffer) ;
			vsync2 = *((unsigned short *) &start_buffer[(IMAGE_WIDTH*IMAGE_HEIGHT)+2]) ;
			//printf("vsync2 : %x \n", vsync2);
		}
		if(vsync1 == 0x55AA && vsync2 == 0x55AA){
			inc ++ ;
			printf("frame found !\n");
		}else{
                	//fclose(yuv_fd);
			//continue ;
			start_buffer = image_buffer ;
			inc ++ ;
		}
		start_buffer += 2 ;
		printf("frame captures \n");
		write_jpegfile(start_buffer, IMAGE_WIDTH, IMAGE_HEIGHT, 1, yuv_fd, 100);
		fclose(yuv_fd);
	}
	fifo_close(1);
	return 0 ;
}
