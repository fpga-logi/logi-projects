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

#include "logilib.h"
#include "includes/gammalut.h"
#include "includes/libppm.h"

#define FRAME_NUM 19

int fd = 0;

int main (int argc, char *argv[])
{
    int row, col ;
    unsigned short int addr = 0 ;
    
    int i;
    for (i=0;i<FRAME_NUM;i++){
        char filename[sizeof "data/frame_000.txt"];
        sprintf(filename, "data/frame_%03d.ppm", i);
	printf("opening %s\n",filename);
        
        // open raw image data
        PPMImage* input = readPPM(filename);
        PPMImage* adjusted = resizePPM(input); 
        // read image data from file and write to display
        for (row = 0; row < 32; row++) {
            for (col = 0; col < 32; col++) {
                int index = row * col;
                unsigned char r = adjusted->data[index].red;
                unsigned char g = adjusted->data[index].green;
                unsigned char b = adjusted->data[index].blue;
                r = gammaLut[r];
                g = gammaLut[g];
                b = gammaLut[b];
	            unsigned int data = (r<<8) | (g<<4) | b;
                logi_write((unsigned char *) &data, 2, addr);
	            addr ++ ;
            }
        } 
	usleep(1000000);
    }
    
    return 0;
}

