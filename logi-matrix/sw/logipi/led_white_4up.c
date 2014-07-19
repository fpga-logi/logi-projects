/*!@file led_white_4up.c
 * @brief testing code: turns the panel to white with two writes
 * @author Xiaofan Li -- Carnegie Mellon University
 * @date July 19th 2014
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
#define BUF_SIZE 4096
#define FIRST_DATA_ADR 0x0000
#define SECOND_DATA_ADR (FIRST_DATA_ADR + ((BUF_SIZE) / 2)) 
/* two byte addrressed*/


int main(int argc, char ** argv){
	int address ;
	unsigned short i ;
	char tx_buf_1[BUF_SIZE];
	char tx_buf_0[BUF_SIZE];

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
		tx_buf_0[i] = gammaLut[0x00]; /* should turn panel to white */
	    tx_buf_1[i] = gammaLut[0x00];
    }		
    
    //loop to refresh the display  
	while(1){
		int i;
	    if((i = wishbone_write(tx_buf_0, BUF_SIZE, FIRST_DATA_ADR)) < BUF_SIZE){
	    	printf("Write error !, returned %d \n", i);
	    }
	    
        if((i = wishbone_write(tx_buf_1, BUF_SIZE, SECOND_DATA_ADR)) < BUF_SIZE){
	    	printf("Write error !, returned %d \n", i);
	    }
        //refresh every second
		//sleep(1);
        //TODO some logic to change display
	}
	return 0;
}
