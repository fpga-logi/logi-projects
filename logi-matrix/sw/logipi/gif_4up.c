/**@file gif_4up.c
 * @author Xiaofan Li
 * @brief Generates frames for 4 panels 
 *        This software binds to specific hardware configuration 
 *        and addressing modes:
 *        
 *         _______________
 *        |       |       |
 *        |  buf0 |  buf0 |
 *        |-------|-------|
 *        |  buf1 |  buf1 |
 *        |=======|=======|
 *        |  buf0 |  buf0 |
 *        |-------|-------| <--- to FPGA <--- to Raspberry Pi
 *        |  buf1 |  buf1 |
 *        |_______|_______|
 */


#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <memory.h>

#include "includes/wishbone_wrapper.h"
#include "includes/gammalut.h"
#include "includes/libppm.h"

#define BYTES_PER_PIXEL 2
#define TOT_BUF_SIZE ((BYTES_PER_PIXEL) * (OUTPUT_HEIGHT) * (OUTPUT_WIDTH))
#define FRAME_BUF_SIZE ((TOT_BUF_SIZE)/2)
#define FRAME_BUF_HEIGHT 16
#define FRAME_BUF_WIDTH ((FRAME_BUF_SIZE)/((FRAME_BUF_HEIGHT)*(BYTES_PER_PIXEL)))
#define FIRST_DATA_ADR 0x00
#define SECOND_DATA_ADR (FRAME_BUF_SIZE / 2) 
int fd = 0;
unsigned char frame_buf_0[FRAME_BUF_SIZE];
unsigned char frame_buf_1[FRAME_BUF_SIZE];

int main (int argc, char *argv[])
{
    int row, col ;
    unsigned int addr = 0 ;
    char filename[sizeof "data/EXAMPLE_FOLDER_MAX_LENGTH/frame_000.txt"];    
    int num_frames = 0;

    if (argc != 3){
	fprintf(stderr,"./test_gif <folder_name> <num_frame>\n");
	exit(1);
    }    
    else {
	num_frames = atoi(argv[2]);
    }

    int i;
    while (1){
      for (i=0;i<num_frames;i++){
          sprintf(filename, "data/%s/frame_%03d.ppm", argv[1],i);
          printf("opening %s\n",filename);
          
          // open raw image data
          PPMImage* input = (PPMImage*)readPPM(filename);
          printf("read file of size %d * %d\n",input->x,input->y);
          PPMImage* adjusted = input;//(PPMImage*)resizePPM(input,RESIZE_CENTER); 
          printf("adjusted to size %d * %d\n",adjusted->x,adjusted->y);
          
          // read image data from file and write to display
          for (row = 0; row < 64; row++) {
              for (col = 0; col < 64; col++) {
                  int index = row * 64 + col;
                  unsigned char r = adjusted->data[index].red;
                  unsigned char g = adjusted->data[index].green;
                  unsigned char b = adjusted->data[index].blue;
                  r = gammaLut[r];
                  g = gammaLut[g];
                  b = gammaLut[b];
                  unsigned int data = (r<<8) | (g<<4) | b;
        	      
                  //hardcoded calculation for buffer index
                  int buf_idx = row / FRAME_BUF_HEIGHT;
                  int local_row,local_col,local_index;
                  if (buf_idx % 2 == 0){
                      //use frame_buf 0
                      if (buf_idx == 0){
                          local_row = row;
                          local_col = col;
                      }
                      else {
                          local_row = row % FRAME_BUF_HEIGHT;
                          local_col = col + OUTPUT_WIDTH;
                      }
                      
                      local_index = local_col+local_row*FRAME_BUF_WIDTH; 
          	          addr = local_index * 2; /* two byte addressed */	
          	          frame_buf_0[addr] = data & 0xff;
          	          frame_buf_0[addr+1] = (data>>8) & 0xff;
                  }
                  else {
                      //use frame_buf 1
                      if (buf_idx == 1){
                          //swap with buf_idx 2
                          local_row = row % FRAME_BUF_HEIGHT;
                          local_col = col;
                      }
                      else{
                          local_row = row % FRAME_BUF_HEIGHT;
                          local_col = col + OUTPUT_WIDTH;
                      }
                      
                      local_index = local_col+local_row*FRAME_BUF_WIDTH; 
          	          addr = local_index * 2; /* two byte addressed */	
          	          frame_buf_1[addr] = data & 0xff;
          	          frame_buf_1[addr+1] = (data>>8) & 0xff;
                  }

              }
          } 
          
          int j;
          //do one write of the frame buffer
          if((j = wishbone_write(frame_buf_0, FRAME_BUF_SIZE, FIRST_DATA_ADR)) < FRAME_BUF_SIZE){
          	printf("Write error !, returned %d \n", j);
          }
          
          if((j = wishbone_write(frame_buf_1, FRAME_BUF_SIZE, SECOND_DATA_ADR)) < FRAME_BUF_SIZE){
          	printf("Write error !, returned %d \n", j);
          }
          
          //sleep one second
          usleep(100000);
          printf("after sleep\n");
      }
    }
    
    return 0;
}

