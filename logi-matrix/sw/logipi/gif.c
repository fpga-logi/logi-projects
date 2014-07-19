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

#define FRAME_BUF_SIZE 2048
#define DATA_ADR 0x00

int fd = 0;
unsigned char frame_buf[FRAME_BUF_SIZE];

int main (int argc, char *argv[])
{
    int row, col ;
    unsigned int addr = 0 ;
    char filename[sizeof "data/EXAMPLE_FOLDER_MAX_LENGTH/frame_000.txt"];    
    int num_frames = 0;

    if (argc != 3){
	fprintf(stderr,"./test_gif <folder_name> <num_frame>");
	exit(1);
    }    
    else {
	num_frames = atoi(argv[2]);
    }

    int i;
    while (1){
      for (i=0;i<num_frames;i++){
          printf("beginning of loop\n");
          sprintf(filename, "data/%s/frame_%03d.ppm", argv[1],i);
          printf("opening %s\n",filename);
          
          // open raw image data
          PPMImage* input = (PPMImage*)readPPM(filename);
          printf("read file of size %d * %d\n",input->x,input->y);
          PPMImage* adjusted = (PPMImage*)resizePPM(input,RESIZE_CENTER); 
          printf("adjusted to size %d * %d\n",adjusted->x,adjusted->y);
          
          // read image data from file and write to display
          for (row = 0; row < 32; row++) {
              for (col = 0; col < 32; col++) {
                  int index = row * 32 + col;
                  unsigned char r = adjusted->data[index].red;
                  unsigned char g = adjusted->data[index].green;
                  unsigned char b = adjusted->data[index].blue;
                  r = gammaLut[r];
                  g = gammaLut[g];
                  b = gammaLut[b];
                  unsigned int data = (r<<8) | (g<<4) | b;
        		
          	addr = index * 2; /* two byte addressed */	
          	frame_buf[addr] = data & 0xff;
          	frame_buf[addr+1] = (data>>8) & 0xff;
              }
          } 
          
          int j;
          //do one write of the frame buffer
          if((j = wishbone_write(frame_buf, FRAME_BUF_SIZE, DATA_ADR)) < FRAME_BUF_SIZE){
          	printf("Write error !, returned %d \n", j);
          }
          
          //sleep one second
          usleep(100000);
          printf("after sleep\n");
      }
    }
    
    return 0;
}

