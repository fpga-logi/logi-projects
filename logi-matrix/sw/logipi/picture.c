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

#include "includes/logilib.h"
#include "includes/gammalut.h"
int fd = 0;

int main (int argc, char *argv[])
{
    int row, col ;
    unsigned short int addr = 0 ;
    // open raw image data
    FILE* fin = fopen (argv[1], "rb");


    // read image data from file and write to display
    for (row = 0; row < 32; row++) {
        for (col = 0; col < 32; col++) {
            unsigned char r = fgetc (fin);
            unsigned char g = fgetc (fin);
            unsigned char b = fgetc (fin);
            r = gammaLut[r];
            g = gammaLut[g];
            b = gammaLut[b];
	    unsigned int data = (r<<8) | (g<<4) | b;
            logi_write((unsigned char *) &data, 2, addr);
	    addr ++ ;
        }
    }
    
    // close image file
    fclose (fin);

    return 0;
}

