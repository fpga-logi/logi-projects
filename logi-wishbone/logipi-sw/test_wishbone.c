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
#include "wishbone_wrapper.h"

int main(int argc, char ** argv){
	int address ;
	unsigned short i ;
	unsigned short writeVals [2048] ;
	struct timeval temp1,temp2;
	long elapsed_u_sec,elapsed_s_sec,elapsed_m_time,elapsed_u_time;
	gettimeofday(&temp1,NULL);
	if((i = wishbone_write(writeVals, 2048, 0)) < 2048){
		printf("Write error !, returned %d \n", i);
	}
	gettimeofday(&temp2,NULL);
	elapsed_s_sec=temp2.tv_sec-temp1.tv_sec;
	elapsed_u_sec=temp2.tv_usec-temp1.tv_usec;
	elapsed_u_time=(elapsed_s_sec)*100000+elapsed_u_sec;	
	printf("Time in Microsecond=%ld \n",elapsed_u_time);
	printf("W Speed=====%d KB/Sec \n",(2048*1000)/elapsed_u_time );
	return 0 ;
}
