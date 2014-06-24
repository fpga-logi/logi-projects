#include "wishbone_wrapper.h"

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

int fd ;

int logi_open(){
	fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
	return 1 ;
}

void logi_close(){
	close(fd);
}

int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address){
	int count = 0 ;
	if(fd == 0){
		logi_open();
	}
	count = pwrite(fd, buffer, length, address);
	return count ;
}
int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address){
	int count = 0 ;
	if(fd == 0){
		logi_open();
	}
	count = pread(fd, buffer, length, address);
	return count ;
}

