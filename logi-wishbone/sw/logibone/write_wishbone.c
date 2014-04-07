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


int main(int argc, char ** argv){
	int fd, address ;
	unsigned short i ;
	unsigned short writeVal ;
	if(argc  < 2){
		printf("not enough arguments \n");
		return 0 ;
	}
	address = (int) strtol(argv[1], NULL, 0);
	writeVal = (unsigned short) strtol(argv[2], NULL, 0);
	printf("Writing 0x%x @ 0x%x \n", writeVal, address);
	fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
	
	if(pwrite(fd, &writeVal, 2, address) < 2){
		printf("Write error !");
	}
	close(fd);
	return 0 ;
}
