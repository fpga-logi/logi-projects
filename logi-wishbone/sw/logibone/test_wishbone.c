#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
//#include <linux/ioctl.h>
#include <sys/ioctl.h>


#define BLOCK_SIZE 65536

int main(int argc, char ** argv){
	int fd, address ;
	unsigned short i ;
	unsigned short writeVals [BLOCK_SIZE] ;
	struct timeval temp1,temp2;
	long elapsed_u_sec,elapsed_s_sec,elapsed_m_time,elapsed_u_time;
	fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
	gettimeofday(&temp1,NULL);
	if(pwrite(fd, writeVals, BLOCK_SIZE*2, 0) < BLOCK_SIZE*2){
		printf("Write error !");
	}
	gettimeofday(&temp2,NULL);
	elapsed_s_sec=temp2.tv_sec-temp1.tv_sec;
	elapsed_u_sec=temp2.tv_usec-temp1.tv_usec;
	elapsed_u_time=(elapsed_s_sec)*1000000+elapsed_u_sec;	
	printf("Time in Microsecond=%ld \n",elapsed_u_time);
	printf("W Speed=====%d KB/Sec \n",(BLOCK_SIZE*2*1000)/elapsed_u_time );
	
	gettimeofday(&temp1,NULL);
        if(pread(fd, writeVals, BLOCK_SIZE*2, 0) < BLOCK_SIZE*2){
                printf("Read error !");
        }
        gettimeofday(&temp2,NULL);
        elapsed_s_sec=temp2.tv_sec-temp1.tv_sec;
        elapsed_u_sec=temp2.tv_usec-temp1.tv_usec;
        elapsed_u_time=(elapsed_s_sec)*1000000+elapsed_u_sec;    
        printf("Time in Microsecond=%ld \n",elapsed_u_time);
        printf("R Speed=====%d KB/Sec \n",(BLOCK_SIZE*2*1000)/elapsed_u_time );


	close(fd);
	return 0 ;
}
