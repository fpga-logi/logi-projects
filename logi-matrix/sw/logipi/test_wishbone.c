#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include "includes/wishbone_wrapper.h"


#define NB_VAL 1024

int main(int argc, char ** argv){
	int address ;
	unsigned short i ;
	unsigned char writeVals [NB_VAL/2], readVals [NB_VAL/2] ;
	struct timeval temp1,temp2;
	long elapsed_u_sec,elapsed_s_sec,elapsed_m_time,elapsed_u_time;
	
	wishbone_init();
	if(argc > 1){
		unsigned long int speed = 0 ;
		speed = atof(argv[1])*1000000L ;
		set_speed(speed);
	}

	for(i=0; i < NB_VAL/2; i ++){
		writeVals[i] = ~i ;
	}		
		
	while(1){
		gettimeofday(&temp1,NULL);
		if((i = wishbone_write(writeVals, NB_VAL, 0x0000)) < NB_VAL){
			printf("Write error !, returned %d \n", i);
		}
		gettimeofday(&temp2,NULL);
		elapsed_s_sec=temp2.tv_sec-temp1.tv_sec;
		elapsed_u_sec=temp2.tv_usec-temp1.tv_usec;
		elapsed_u_time=(elapsed_s_sec)*100000+elapsed_u_sec;	
		printf("Time in Microsecond=%ld \n",elapsed_u_time);
		printf("W Speed=====%d KB/Sec \n",(NB_VAL*1000)/elapsed_u_time );
	
		gettimeofday(&temp1,NULL);
		if((i = wishbone_read(readVals, NB_VAL, 0x0000)) < NB_VAL){
		        printf("Read error !, returned %d \n", i);
		}
		gettimeofday(&temp2,NULL);
		elapsed_s_sec=temp2.tv_sec-temp1.tv_sec;
		elapsed_u_sec=temp2.tv_usec-temp1.tv_usec;
		elapsed_u_time=(elapsed_s_sec)*100000+elapsed_u_sec;    
		printf("Time in Microsecond=%ld \n",elapsed_u_time);
		printf("R Speed=====%d KB/Sec \n",(NB_VAL*1000)/elapsed_u_time );
	
		for(i=0; i < NB_VAL/2; i ++){
		        if(readVals[i] != writeVals[i]){
				printf("Transfer failed [%u] = %04x \n", i, readVals[i]);
			}
		}
		sleep(1);
	}
	return 0 ;
}
