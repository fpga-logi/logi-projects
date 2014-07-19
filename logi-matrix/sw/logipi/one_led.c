
/*!@file led_white.c
 * @brief testing code: turns the panel to white
 * @author Xiaofan Li -- Carnegie Mellon University
 * @date July 8th 2014
 */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
//#include <sys/stat.h>
//#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
//#include <sys/ioctl.h>
#include "includes/wishbone_wrapper.h" /* wrapper for the wishbone */
#include "includes/gammalut.h"


//custom defines
#define BUF_SIZE 0x7fff
#define DATA_ADR 0x0000
#define COLOR 0x00

int main(int argc, char ** argv){
	int address ;
	unsigned short i ;
	char tx_buf[BUF_SIZE];

    //initialize the wishbone bus
	wishbone_init();
	
    //if custom speed
    if(argc > 1){
		unsigned long int speed = 0 ;
		speed = atof(argv[1])*1000000L ;
		set_speed(speed);
	}
    
    //filling the tx_buffer with stuff
	for(i=0; i < BUF_SIZE; i ++){
		tx_buf[i] = gammaLut[COLOR];
	}		
    
	if((i = wishbone_write(tx_buf, BUF_SIZE, DATA_ADR)) < BUF_SIZE){
		printf("Write error !, returned %d \n", i);
	}
	return 0;
}
