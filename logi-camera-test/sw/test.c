#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include "wishbone_wrapper.h"
#include "config.h"


FILE * log_file;
char text_buffer [512] ;

#define SHOW_IMG "fbi -T 2 -a grabbed_frame0000.jpg"
#define RM_IMG "rm *.jpg"

enum dbg_level{
	INFO,
	WARNING, 
	ERROR
};


int kbhit()
{
    struct timeval tv = { 0L, 0L };
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(0, &fds);
    return select(1, &fds, NULL, NULL, &tv);
}

void init_test_log(){
	char buffer [256] ;	
	unsigned long int ts = time(NULL); 
	sprintf(buffer, LOG_PATH, ts);
	log_file = fopen(buffer, "w+");
	if(log_file == NULL){
		printf("Cannot create log file \n");	
	}
	fwrite("TIMESTAMP, TEST_NAME, TYPE, TEST_MSG\n", sizeof(char), 37, log_file);
}

void close_test_log(){
	fclose(log_file);
}

void test_log(enum dbg_level lvl, char * test_name, char * fmt, ...){
	int msg_size ;	
	unsigned long int ts;
	va_list args;
    	va_start(args,fmt);
	ts = time(NULL); 
	msg_size = sprintf(text_buffer, "%ld", ts);
	fwrite(text_buffer, sizeof(char), msg_size, log_file); //writing timestamp to file
	fwrite(",", sizeof(char), 1, log_file); 
	fwrite(test_name, sizeof(char), strlen(test_name), log_file); //writing test name
	fwrite(",", sizeof(char), 1, log_file); 
	msg_size = vsprintf(text_buffer, fmt, args);
	switch(lvl){
		case INFO :
			if(log_file != NULL){
				fwrite("INFO,", sizeof(char), 5, log_file);			
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("INFO : ");			
			vprintf(fmt,args);
			break ;
		case WARNING : 
			if(log_file != NULL){
				fwrite("WARNING,", sizeof(char), 8, log_file);				
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("WARNING : ");
			vprintf(fmt,args);
			break ;
		case ERROR : 			
			if(log_file != NULL){
				fwrite("ERROR,", sizeof(char), 6, log_file);				
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("ERROR : ");
			vprintf(fmt,args);
			break ;
		default :
			break ;	
	}
	va_end(args);
	printf("\n");
}	


#define IMAGE_WIDTH 160
#define IMAGE_HEIGHT 120
#define NB_CHAN 2


char rgb_file_name [128] ;
char yuv_file_name [128] ;
char jpeg_file_name [128] ;




int min(int a, int b){
	if(a > b ){
		return b ;	
	}
	return a ;
}

int grab_frame(void){
	unsigned short cmd_buffer[8] ;
	unsigned short vsync1, vsync2 ;
	FILE * rgb_fd, * yuv_fd, * jpeg_fd ;
	int i,j, res, inc ;
	unsigned int nbFrames = 1 ;
	unsigned int pos = 0 ;
	unsigned int nb = 0 ;
	unsigned char * image_buffer, * start_buffer, * end_ptr; //yuv frame buffer
	unsigned char * rgb_buffer ;
	unsigned short fifo_state, fifo_data ;
	float y, u, v ;
	float r, g, b ;
	unsigned int retry_counter = 0 ;
	unsigned int retry_pixel = 0 ;
	image_buffer = (unsigned char *) malloc(IMAGE_WIDTH*IMAGE_HEIGHT*NB_CHAN*4+1024); // 1024 extra to ease the read function
        rgb_buffer = (unsigned char *) malloc(IMAGE_WIDTH*IMAGE_HEIGHT*3);
	if(image_buffer == NULL || rgb_buffer == NULL){
		printf("allocation error ! \n");
		return -1 ;
	}

	for(inc = 0 ; inc < (nbFrames && retry_counter < 5) ; ){
		/*sprintf(yuv_file_name, "./grabbed_frame%04d.yuv", inc);
		sprintf(rgb_file_name, "./grabbed_frame%04d.rgb", inc);*/ 
		sprintf(jpeg_file_name, "./grabbed_frame%04d.jpg", inc);
		/*rgb_fd  = fopen(rgb_file_name, "wb");
		yuv_fd  = fopen(yuv_file_name, "wb");*/
		jpeg_fd  = fopen(jpeg_file_name, "wb");
		if(jpeg_fd == NULL){
			printf("Error opening output file \n");
			exit(EXIT_FAILURE);
		}
		printf("issuing reset to fifo \n");
		cmd_buffer[0] = 0 ;
		cmd_buffer[1] = 0 ;
		cmd_buffer[2] = 0 ;
		wishbone_write((unsigned char *) cmd_buffer, 6, FIFO_ADDR+FIFO_CMD_OFFSET);
		wishbone_read((unsigned char *) cmd_buffer, 6, FIFO_ADDR+FIFO_CMD_OFFSET);
		printf("fifo size : %d, free : %d, available : %d \n", cmd_buffer[0], cmd_buffer[1], cmd_buffer[2]);  // reading and printing fifo states
		/*wishbone_read((unsigned char *) cmd_buffer, 6, 0);
		for(i = 0 ; i < 6; i ++){
                                printf("%02x, ", cmd_buffer[i]);
                }*/
		nb = 0 ;
		retry_pixel = 0 ; 
		while(nb < ((IMAGE_WIDTH)*(IMAGE_HEIGHT)*NB_CHAN)*3 && retry_pixel < 10000){
			wishbone_read((unsigned char *) cmd_buffer, 6, FIFO_ADDR+FIFO_CMD_OFFSET);
			while(cmd_buffer[2] < 1024 && retry_pixel < 10000){
				 wishbone_read((unsigned char *) cmd_buffer, 6, FIFO_ADDR+FIFO_CMD_OFFSET);
				 retry_pixel ++ ;
			}
			wishbone_read_noinc(&image_buffer[nb], 2048, FIFO_ADDR);
			nb += 2048 ;
		}
		if(retry_pixel == 10000){
			printf("no camera detected !\n");
                        fclose(jpeg_fd);
			return -1 ;
		}
		printf("nb : %u \n", nb);
		start_buffer = image_buffer ;
		end_ptr = &image_buffer[IMAGE_WIDTH*IMAGE_HEIGHT*NB_CHAN*3];
		vsync1 = *((unsigned short *) start_buffer) ;
		vsync2 = *((unsigned short *) &start_buffer[(IMAGE_WIDTH*IMAGE_HEIGHT*NB_CHAN)+2]) ;
		while(vsync1 != 0x55AA && vsync2 != 0x55AA && start_buffer < end_ptr){
			start_buffer+=2 ;
			vsync1 = *((unsigned short *) start_buffer) ;
			vsync2 = *((unsigned short *) &start_buffer[(IMAGE_WIDTH*IMAGE_HEIGHT*NB_CHAN)+2]) ;
		}
		if(vsync1 == 0x55AA && vsync2 == 0x55AA){
			inc ++ ;
			printf("frame found !\n");
		}else{
			printf("sync not found !\n");
			/*fclose(rgb_fd);
                	fclose(yuv_fd);*/
			fclose(jpeg_fd);
			retry_counter ++ ;
			continue ;
		}
		start_buffer += 2 ;
		for(i = 0 ; i < IMAGE_WIDTH*IMAGE_HEIGHT ; i ++){
			y = (float) start_buffer[(i*NB_CHAN)] ;
			if(NB_CHAN == 2){
				if(i%2 == 0){
					u = (float) start_buffer[(i*2)+1];
					v = (float) start_buffer[(i*2)+3];
				}else{
					u = (float) start_buffer[(i*2)-1];
        	        		v = (float) start_buffer[(i*2)+1];
				}
			}else{
				u = 128 ;
				v = 128 ;
			}
			r =  y + (1.4075 * (v - 128.0));
			g =  y - (0.3455 * (u - 128.0)) - (0.7169 * (v - 128.0));
			b =  y + (1.7790 * (u - 128.0)) ;
			rgb_buffer[(i*3)] = (unsigned char) abs(min(r, 255)) ;
			rgb_buffer[(i*3)+1] = (unsigned char) abs(min(g, 255)) ;
			rgb_buffer[(i*3)+2] = (unsigned char) abs(min(b, 255)) ;
		} 
		//fwrite(start_buffer, IMAGE_WIDTH*IMAGE_HEIGHT*NB_CHAN, 1, yuv_fd);
		//fwrite(rgb_buffer, IMAGE_WIDTH*IMAGE_HEIGHT*3, 1, rgb_fd);
		write_jpegfile(rgb_buffer, IMAGE_WIDTH, IMAGE_HEIGHT, 3, jpeg_fd, 100);
		/*fclose(rgb_fd);
		fclose(yuv_fd);*/
		fclose(jpeg_fd);
	}
	if(retry_counter == 5){
		return -1 ;
	}
	return 0 ;
}

int main(int argc, char ** argv){
	char c [10];	
	char * argv2 [3];
	init_test_log();	
	test_log(INFO,"MAIN", "Press Enter to begin testing \n");
	while(fgets(c, 2, stdin) == NULL);
	test_log(INFO, "MAIN","----------------Loading FPGA--------------\n");	
	// load fpga
	system(LOAD_CMD);
	//
	sleep(1);
	system(RM_IMG);
	test_log(INFO, "MAIN","-----------------Starting Test-------------\n");
	test_log(INFO, "COM","-----------------Cam Test---------------\n");
	if(grab_frame() >= 0){
		system(SHOW_IMG);
		printf("Do the low resolution image look good ? (y=yes, n=no):");
		while(fgets(c, 2, stdin) == NULL || (c[0] != 'n' && c[0] != 'y')) printf("Do the low resolution image look good ? (y=yes, n=no):");
		if(c[0] == 'n'){
			test_log(ERROR, "CAM","CAM test failed");	
		}else{
			test_log(INFO, "CAM","CAM test passed");
		}
	}else{
		test_log(ERROR, "CAM","CAM test failed");
	}
	close_test_log();
	return 0 ;
	
}
