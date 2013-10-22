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
	int fd, address ;
	unsigned short i ;
	unsigned short readVal ;
	if(argc  < 1){
		printf("not enough arguments \n");
		return 0 ;
	}
	address = (int) strtol(argv[1], NULL, 0);
	wishbone_read(&readVal, 2, address);
	printf("0x%x \n", readVal);
	return 0 ;
}
