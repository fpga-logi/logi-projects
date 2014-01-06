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
	unsigned int i = 0 ;
	unsigned short int ledVal = 0xFFFF ;
	wishbone_write(&ledVal, 2, REG1);
	for(i = 0 ; i < 8 ; i ++){
		ledVal = ~ledVal ;
		wishbone_write(&ledVal, 2, REG1);
		sleep(1);
	}
	
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
	char c ;		
	printf("----------------Loading FPGA--------------\n");	
	// load fpga
	//
	print("-----------------Starting Test-------------\n");
	print("-------------------GPIO Test---------------\n");
	if(testPMOD12() < 0){
		printf("PMOD1-2 test failed \n");	
		return -1 ;	
	}
	if(testPMOD34() < 0){
		printf("PMOD3-4 test failed \n");	
		return -1 ;
	}
	print("-----------------Memory Test---------------\n");
	if(testCom() < 0) {
		printf("Communication test failed \n");	
		return -1 ;
	}
	printf("----------------Testing LEDs--------------\n");
	testLED();
	printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	while(fgets(&c, 1, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	if(c == 'n'){
		printf("Led test failed \n");	
		return -1 ;	
	}
	while(c != 'y'){
		testLED();
		printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
		while(fgets(&c, 1, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
		if(c == 'n'){
			printf("Led test failed \n");	
			return -1 ;	
		}
		printf("\n");
	}
	printf("\n");
	printf("----------------Testing PB--------------\n");
	printf("Click the Push buttons \n");
	if(testPB() < 0){
		printf("PB test failed \n");	
		return -1 ;
	}
	printf("----------------Testing SW--------------\n");
	printf("Switch the switches \n");
	if(testSW() < 0){
		printf("SW test failed \n");	
		return -1 ;
	}
	printf("----------------Testing SDRAM--------------\n");	
	if(testSdram() < 0){
		printf("SDRAM test failed \n");	
		return -1 ;
	}

	printf("----------------Testing LVDS--------------\n");	
	if(testLVDS() < 0){
		printf("SDRAM test failed \n");	
		return -1 ;
	}

	return 0 ;
}
