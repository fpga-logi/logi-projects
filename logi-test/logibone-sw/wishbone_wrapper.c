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

int fd ;

void logibone_init(){
	fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
}

unsigned int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0;
	unsigned int count = 0 ;
	if(fd == 0){
		logibone_init();
	}
	count = pwrite(fd, buffer, length, address);
	return count ;
}
unsigned int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0;
	unsigned int count = 0 ;
	if(fd == 0){
		logibone_init();
	}
	count = pread(fd, buffer, length, address);
	return count ;
}


