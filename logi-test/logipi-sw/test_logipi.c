#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include "wishbone_wrapper.h"


//DEFINE WHICH TESTS TO RUN
#define TEST_SDRAM 	

#define TEST_LED	
#define TEST_PMOD_1_2
#define TEST_PMOD_3_4
#define TEST_SW
#define TEST_PB		
#define TEST_COMM	
#define TEST_LVDS 	




#define GPIO0 0x0002
#define GPIO0DIR 0x0003
#define GPIO1 0x0004
#define GPIO1DIR 0x0005
#define GPIO2 0x0006
#define GPIO2DIR 0x0007
#define REG0  0x0010
#define REG1  0x0011
#define REG2  0x0012
#define REG_DEBUG_RAM 0x0013
#define MEM0  0x1000

#define LED_MASK 0x0003
#define PB_MASK 0x0003
#define SW_MASK 0x000C
#define SDRAM_ERROR_MASK 0x0010
#define SDRAM_SUCCESS_MASK 0x0020

#define SATA_WRITE_SHIFT 2
#define SATA_READ_SHIFT 6

#define GPIO_TEST1_DIR 0x5555	
#define GPIO_TEST1_1 0x1111
#define GPIO_TEST1_2 0x4444

#define GPIO_TEST2_DIR 0xAAAA	
#define GPIO_TEST2_1 0x2222
#define GPIO_TEST2_2 0x8888

char * bitFilePath = "../logipi_test.bit" ;

enum dbg_level{
	INFO,
	WARNING, 
	ERROR
};


int kbhit()
{
    struct timeval tv = { 0L, 0L };
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(0, &fds);
    return select(1, &fds, NULL, NULL, &tv);
}

void init_test_log(){
}

void close_test_log(){
}

void test_log(enum dbg_level lvl, char * fmt, ...){
	va_list args;
    	va_start(args,fmt);
	switch(lvl){
		case INFO :
			printf("INFO : ");
			vprintf(fmt,args);
			break ;
		case WARNING : 
			printf("WARNING : ");
			vprintf(fmt,args);
			break ;
		case ERROR : 
			printf("ERROR : ");
			vprintf(fmt,args);
			break ;
		default :
			break ;	
	}
	va_end(args);
	printf("\n");
}	


int testPMOD12(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = GPIO_TEST1_DIR ;
	valBuf = GPIO_TEST1_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_1 << 1)){
		if((valBuf & 0x00FF) != ((GPIO_TEST1_1 << 1) & 0x00FF)){
			printf("Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_1 << 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD2\n");		
		}	
		return -1 ;
	}
	valBuf = GPIO_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_2 << 1) ){
		if((valBuf & 0x00FF) != ((GPIO_TEST1_2 << 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_2 << 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD2\n");		
		}	 
		return -1 ;
	}

	dirBuf = GPIO_TEST2_DIR ;
	valBuf = GPIO_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_1 >> 1)){
		if((valBuf & 0x00FF) != ((GPIO_TEST2_1 >> 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_1 >> 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD2\n");		
		}		 
		return -1 ;
	}
	valBuf = GPIO_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_2 >> 1) ){
		if((valBuf & 0x00FF) != ((GPIO_TEST2_2 >> 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_2 >> 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD2\n");		
		}
		return -1 ;
	}
	return 0 ;
}

int testPMOD34(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = GPIO_TEST1_DIR ;
	valBuf = GPIO_TEST1_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO1DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_1 << 1)){
		if((valBuf & 0x00FF) != ((GPIO_TEST1_1 << 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_1 << 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD4\n");		
		}		
		return -1 ;
	}
	valBuf = GPIO_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_2 << 1) ){
		if((valBuf & 0x00FF) != ((GPIO_TEST1_2 << 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_2 << 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD4\n");		
		}
		return -1 ;
	}
	dirBuf = GPIO_TEST2_DIR ;
	valBuf = GPIO_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO1DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_1 >> 1)){
		if((valBuf & 0x00FF) != ((GPIO_TEST2_1 >> 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_1 >> 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD4\n");		
		}		
		return -1 ;
	}
	valBuf = GPIO_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_2 >> 1) ){
		if((valBuf & 0x00FF) != ((GPIO_TEST2_2 >> 1) & 0x00FF)){
			test_log(ERROR,"Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_2 >> 1) & 0xFF00)){
			test_log(ERROR,"Failure on PMOD4\n");		
		}		
		return -1 ;
	}

	return 0 ;
}


int testPB(){
	unsigned int i = 0 ;
	unsigned short int pbVal = PB_MASK, pbValOld = PB_MASK, valMask = 0x00;
	do{
		pbValOld = pbVal ;		
		wishbone_read((unsigned char *) &pbVal, 2, REG2);
		pbVal &= PB_MASK ;
		if((pbVal & 0x01) != (pbValOld & 0x01)) valMask |= 0x01 ;
		if((pbVal & 0x02) != (pbValOld & 0x02)) valMask |= 0x02 ;
		if(kbhit()){
			char c ;
			c = fgetc(stdin);
			if(c == '\n'){
				return -1 ;			
			}		
		}
	}while(valMask != 0x03);
	return 0 ;
}

int testSW(){
	unsigned int i = 0 ;
	unsigned short int swVal = SW_MASK, swValOld = SW_MASK, valMask = 0x00;
	wishbone_read((unsigned char *) &swVal, 2, REG2);
	swVal = ((swVal & SW_MASK) >> 2) ;
	do{
		swValOld = swVal ;		
		wishbone_read((unsigned char *) &swVal, 2, REG2);
		swVal = ((swVal & SW_MASK) >> 2) ;
		if((swVal & 0x01) != (swValOld & 0x01)) valMask |= 0x01 ;
		if((swVal & 0x02) != (swValOld & 0x02)) valMask |= 0x02 ;
		if(kbhit()){
			char c ;
			c = fgetc(stdin);
			if(c == '\n'){
				return -1 ;			
			}		
		}
	}while(valMask != 0x03);
	return 0 ;
}

int testLED(){
	unsigned int i = 0 ;
	unsigned short int ledVal = 0x01 ;
	wishbone_write((unsigned char *) &ledVal, 2, REG0);
	for(i = 0 ; i < 2 ; i ++){
		ledVal = (~ledVal) & LED_MASK ;
		wishbone_write((unsigned char *) &ledVal, 2, REG0);
		sleep(1);
	}
	
}

int testCom(){
	unsigned short i ;
	unsigned short writeVals [2048] ;
	unsigned short readVals [2048] ;
	srand(time(NULL));
	for(i = 0; i < 2048; i ++){
		writeVals[i] = rand()%0xFFFF;	
	}	

	if((i = wishbone_write((unsigned char *) writeVals, 2048, MEM0)) < 2048){
		test_log(ERROR,"Write error !, returned %d \n", i);
		return -1 ;
	}
	if((i = wishbone_read((unsigned char *) readVals, 2048, MEM0)) < 2048){
		test_log(ERROR,"Read error !, returned %d \n", i);
		return -1 ;
	}
	for(i = 0; i < 512; i ++){
		if(readVals[i] != writeVals[i]){
			test_log(ERROR,"Corrupted Value @%i\n", i);	
			test_log(ERROR,"Expecting  0x%04x , got 0x%04x \n", writeVals[i], readVals[i]);	 	
			return -1 ;	
		}
	}
	
	return 0 ;
}

int testSdram(){
	unsigned short int c ;
	wishbone_read((unsigned char *) &c, 2, REG2);
	if(c & SDRAM_SUCCESS_MASK){
		return 0 ;	
	}	
	if(c & SDRAM_ERROR_MASK){
		return -1 ;	
	}
	return 1 ;
}

int getSdramDump(){
	unsigned short int buffer[8];
	unsigned char i ;
	wishbone_read((unsigned char *) buffer, 16, REG_DEBUG_RAM);
	test_log(ERROR,"test failed : %d \n", (unsigned int) (buffer[0] & 0x8000 == 0x8000));
	test_log(ERROR,"at address : %08x \n", ((buffer[0] & 0x7FFF) | (buffer[1] << 15)));
	test_log(ERROR,"with pattern : %04x%04x \n", buffer[5], buffer[6]);
	test_log(ERROR,"obtained : %04x%04x \n", buffer[2], buffer[3]);
	return 0 ;
}

int testLVDS(){
        unsigned short int write_val, read_val ;
        write_val = 1 << SATA_WRITE_SHIFT ;
        wishbone_write((unsigned char *) &write_val, 2, REG0);
        wishbone_read((unsigned char *) & read_val, 2, REG2);
        read_val = (read_val >> SATA_READ_SHIFT) & 0x01 ;
        if(!read_val){
                return -1 ;
        }
        write_val = 0;
        wishbone_write((unsigned char *) &write_val, 2, REG0);
        wishbone_read((unsigned char *) &read_val, 2, REG2);
        read_val = (read_val >> SATA_READ_SHIFT) & 0x01 ;
        if(read_val){
                 return -1 ;
        }
        return 0 ;
}


int main(int argc, char ** argv){
	char c ;	
	char * argv2 [3];	
	test_log(ERROR,"Press Enter to begin testing \n");
	while(fgets(&c, 1, stdin)== NULL);
	init_test_log();
	test_log(INFO,"----------------Loading FPGA--------------\n");	
	// load fpga
	system("/usr/bin/logi_loader logipi_test.bit");
	//
	sleep(1);
	test_log(INFO,"-----------------Starting Test-------------\n");
	
	
	#ifdef TEST_PMOD_1_2
	test_log(INFO,"-------------------GPIO Test---------------\n");
	if(testPMOD12() < 0){
		test_log(ERROR,"PMOD1-2 test failed \n");	
		return -1 ;	
	}
	#endif
	#ifdef TEST_PMOD_3_4
	if(testPMOD34() < 0){
		test_log(ERROR,"PMOD3-4 test failed \n");	
		return -1 ;
	}
	#endif
	
	#ifdef TEST_COMM
	test_log(INFO,"-----------------Communication Test---------------\n");
	if(testCom() < 0) {
		test_log(ERROR,"Communication test failed \n");	
		return -1 ;
	}
	#endif
	
	#ifdef TEST_LED
	test_log(INFO,"----------------Testing LEDs--------------\n");
	testLED();
	printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	while(fgets(&c, 2, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	printf("%c \n", c);
	if(c == 'n'){
		test_log(INFO,"Led test failed \n");	
		return -1 ;	
	}
	while(c != 'y'){
		testLED();
		printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
		while(fgets(&c, 2, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
		if(c == 'n'){
			test_log(ERROR,"Led test failed \n");	
			return -1 ;	
		}
		printf("\n");
	}
	#endif
	
	#ifdef TEST_PB
	printf("\n");
	test_log(INFO,"----------------Testing PB--------------\n");
	printf("Click the Push buttons, press enter if nothing happens \n");
	if(testPB() < 0){
		test_log(ERROR,"PB test failed \n");	
		return -1 ;
	}
	#endif
	
	#ifdef TEST_SW
	test_log(INFO,"----------------Testing SW--------------\n");
	printf("Switch the switches, press enter if nothing happens \n");
	if(testSW() < 0){
		test_log(ERROR,"SW test failed \n");	
		return -1 ;
	}
	#endif
	
	#ifdef TEST_SDRAM
	test_log(INFO,"----------------Testing SDRAM--------------\n");	
	while(testSdram() > 0) sleep(1);
	if(testSdram() < 0){
		test_log(ERROR,"SDRAM test failed \n");
		getSdramDump();	
		return -1 ;
	}
	#endif

	#ifdef TEST_LVDS
	test_log(INFO,"----------------Testing LVDS--------------\n");	
	if(testLVDS() < 0){
		test_log(ERROR,"LVDS test failed \n");	
		return -1 ;
	}
	test_log(INFO,"---------------Test Passed ----------------\n");
	#endif
	close_test_log();
	return 0 ;
	
}
