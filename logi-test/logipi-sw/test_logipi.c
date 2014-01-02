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

#define GPIO0 0x0002
#define GPIO0DIR 0x0003
#define GPIO1 0x0004
#define GPIO1DIR 0x0005
#define GPIO2 0x0006
#define GPIO2DIR 0x0007
#define REG0  0x0008
#define REG1  0x0009
#define REG2  0x000A
#define MEM0  0x1000

int testPMOD12(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = 0x0F0F ;
	valBuf = 0x0505 ; 
	wishbone_write(&dirBuf, 2, GPIO0DIR);
	wishbone_write(&valBuf, 2, GPIO0);
	whihbone_read(&valBuf, 2, GPIO0);
	valBuf = valBuf & dirBuf ;
	if(valBuf != 0x5050) return -1 ;
	valBuf = 0x0A0A ;
	wishbone_write(&valBuf, 2, GPIO0);
	whihbone_read(&valBuf, 2, GPIO0);
	valBuf = valBuf & dirBuf ;
	if(valBuf != 0xA0A0) return -1 ;

	dirBuf = 0xF0F0 ;
	valBuf = 0x5050 ;
	wishbone_write(&dirBuf, 2, GPIO0DIR);
	wishbone_write(&valBuf, 2, GPIO0);
	whihbone_read(&valBuf, 2, GPIO0);
	valBuf = valBuf & (~dirBuf) ;
	if(valBuf != 0x0505) return -1 ;
	valBuf = 0xA0A0 ;
	wishbone_write(&valBuf, 2, GPIO0);
	whihbone_read(&valBuf, 2, GPIO0);
	valBuf = valBuf & (~dirBuf) ;
	if(valBuf != 0x0A0A) return -1 ;

	return 0 ;
}

int testPMOD34(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = 0x0F0F ;
	valBuf = 0x0505 ; 
	wishbone_write(&dirBuf, 2, GPIO1DIR);
	wishbone_write(&valBuf, 2, GPIO1);
	whihbone_read(&valBuf, 2, GPIO1);
	valBuf = valBuf & dirBuf ;
	if(valBuf != 0x5050) return -1 ;
	valBuf = 0x0A0A ;
	wishbone_write(&valBuf, 2, GPIO1);
	whihbone_read(&valBuf, 2, GPIO1);
	valBuf = valBuf & dirBuf ;
	if(valBuf != 0xA0A0) return -1 ;

	dirBuf = 0xF0F0 ;
	valBuf = 0x5050 ;
	wishbone_write(&dirBuf, 2, GPIO1DIR);
	wishbone_write(&valBuf, 2, GPIO1);
	whihbone_read(&valBuf, 2, GPIO1);
	valBuf = valBuf & (~dirBuf) ;
	if(valBuf != 0x0505) return -1 ;
	valBuf = 0xA0A0 ;
	wishbone_write(&valBuf, 2, GPIO1);
	whihbone_read(&valBuf, 2, GPIO1);
	valBuf = valBuf & (~dirBuf) ;
	if(valBuf != 0x0A0A) return -1 ;

	return 0 ;
}


int testPB(){
	
}

int testSW(){
}

int testLED(){
}

int testCom(){
	unsigned short i ;
	unsigned short writeVals [2048] ;
	unsigned short readVals [2048] ;
	srand(time(NULL));
	for(i = 0; i < 2048; i ++){
		writeVal[i] = rand()%0xFFFF;	
	}	

	if((i = wishbone_write(writeVals, 2048, MEM0)) < 2048){
		printf("Write error !, returned %d \n", i);
		return -1 ;
	}
	if((i = wishbone_write(readVals, 2048, MEM0)) < 2048){
		printf("Read error !, returned %d \n", i);
		return -1 ;
	}
	for(i = 0; i < 2048; i ++){
		if(readVals[i] != writeVals[i]) return -1 ;	
	}
	
	return 0 ;
}





int main(int argc, char ** argv){
	testPMOD12();
	testPMOD34();
	testCom();
	return 0 ;
}
