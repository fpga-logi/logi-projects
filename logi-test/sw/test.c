#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include "wishbone_wrapper.h"
#include "config.h"


FILE * log_file;
char text_buffer [512] ;

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
	char buffer [256] ;	
	unsigned long int ts = time(NULL); 
	sprintf(buffer, LOG_PATH, ts);
	log_file = fopen(buffer, "w+");
	if(log_file == NULL){
		printf("Cannot create log file \n");	
	}
	fwrite("TIMESTAMP, TEST_NAME, TYPE, TEST_MSG\n", sizeof(char), 37, log_file);
}

void close_test_log(){
	fclose(log_file);
}

void test_log(enum dbg_level lvl, char * test_name, char * fmt, ...){
	int msg_size ;	
	unsigned long int ts;
	va_list args;
    	va_start(args,fmt);
	ts = time(NULL); 
	msg_size = sprintf(text_buffer, "%ld", ts);
	fwrite(text_buffer, sizeof(char), msg_size, log_file); //writing timestamp to file
	fwrite(",", sizeof(char), 1, log_file); 
	fwrite(test_name, sizeof(char), strlen(test_name), log_file); //writing test name
	fwrite(",", sizeof(char), 1, log_file); 
	msg_size = vsprintf(text_buffer, fmt, args);
	switch(lvl){
		case INFO :
			if(log_file != NULL){
				fwrite("INFO,", sizeof(char), 5, log_file);			
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("INFO : ");			
			vprintf(fmt,args);
			break ;
		case WARNING : 
			if(log_file != NULL){
				fwrite("WARNING,", sizeof(char), 8, log_file);				
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("WARNING : ");
			vprintf(fmt,args);
			break ;
		case ERROR : 			
			if(log_file != NULL){
				fwrite("ERROR,", sizeof(char), 6, log_file);				
				fwrite(text_buffer, sizeof(char), msg_size, log_file);
			}
			printf("ERROR : ");
			vprintf(fmt,args);
			break ;
		default :
			break ;	
	}
	va_end(args);
	printf("\n");
}	


#ifdef LOGIPI


#define BCM2708_PERI_BASE        0x20000000
#define GPIO_BASE                (BCM2708_PERI_BASE + 0x200000) /* GPIO controller */

#define PAGE_SIZE (4*1024)
#define BLOCK_SIZE (4*1024)

#define INP_GPIO(g) *(gpio+((g)/10)) &= ~(7<<(((g)%10)*3))
#define OUT_GPIO(g) *(gpio+((g)/10)) |=  (1<<(((g)%10)*3))
#define SET_GPIO_ALT(g,a) *(gpio+(((g)/10))) |= (((a)<=3?(a)+4:(a)==4?3:2)<<(((g)%10)*3))

#define GPIO_REG(g) *(gpio+(((g)/10)))

#define GPIO_SET *(gpio+7)  // sets   bits which are 1 ignores bits which are 0
#define GPIO_CLR *(gpio+10) // clears bits which are 1 ignores bits which are 0
#define GPIO_LEV *(gpio+13) // clears bits which are 1 ignores bits which are 0


#define GPIO_GEN_2 27
#define GPIO_GEN_3 22
#define GPIO_GEN_4 4

int  mem_fd;
void *gpio_map;

// I/O access
volatile unsigned *gpio;
unsigned cfg_save[3] ;

void initGPIO(){
	unsigned int i = 0 ;
	if ((mem_fd = open("/dev/mem", O_RDWR|O_SYNC) ) < 0) {
		printf("can't open /dev/mem \n");
		exit(EXIT_FAILURE);
	}

	/* mmap GPIO */
	gpio_map = mmap(
	NULL,             //Any adddress in our space will do
	BLOCK_SIZE,       //Map length
	PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
	MAP_SHARED,       //Shared with other processes
	mem_fd,           //File to map
	GPIO_BASE         //Offset to GPIO peripheral
	);

	close(mem_fd); //No need to keep mem_fd open after mmap

	if (gpio_map == MAP_FAILED) {
		printf("mmap error %04x\n", (unsigned int) gpio_map);//errno also set!
		exit(EXIT_FAILURE);
	}

	// Always use volatile pointer!
	gpio = (volatile unsigned *)gpio_map;

	for(i = 0; i < 3 ; i ++){
		switch(i){
			case 0:
				cfg_save[i] = GPIO_REG(GPIO_GEN_2);
				break ;
			case 1:
				cfg_save[i] = GPIO_REG(GPIO_GEN_3);
				break ;
			case 2:
				cfg_save[i] = GPIO_REG(GPIO_GEN_4);
				break ;
			default: 
				break ;
		};
		
	}

	OUT_GPIO(GPIO_GEN_2);
	OUT_GPIO(GPIO_GEN_3);
	OUT_GPIO(GPIO_GEN_4);
}

void closeGPIOs(){
	unsigned int i ;
	for(i = 0; i < 3 ; i ++){
		switch(i){
			case 0:
				GPIO_REG(GPIO_GEN_2) = cfg_save[i] ;
				break ;
			case 1:
				GPIO_REG(GPIO_GEN_3) = cfg_save[i] ;
				break ;
			case 2:
				GPIO_REG(GPIO_GEN_4) = cfg_save[i] ;
				break ;
			default: 
				break ;
		};
		
	}
}

void setGen2(){
	GPIO_SET =  1 << GPIO_GEN_2 ;
}
void clrGen2(){
	GPIO_CLR = 1 << GPIO_GEN_2 ;
}

void setGen3(){
	GPIO_SET =  1 << GPIO_GEN_3 ;
}
void clrGen3(){
	GPIO_CLR = 1 << GPIO_GEN_3 ;
}

void setGen4(){
	GPIO_SET =  1 << GPIO_GEN_4 ;
}
void clrGen4(){
	GPIO_CLR = 1 << GPIO_GEN_4 ;
}


int testRpiGpio(){
	unsigned short valBuf = 0 ;
	int res = 0 ;
	initGPIO();
	wishbone_write((unsigned char *) &valBuf, 2, GPIO2DIR); // all inputs
	setGen3();
	clrGen2();
	clrGen4();
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	if((valBuf & 0x01C0) != 0x0080){
		test_log(ERROR, "RPI_GPIO", "RPI gpio 4-3-2 test failed, expected %04x got %04x \n", 0x0080, (valBuf & 0x01C0)); 
		res = -1 ;
	}
	clrGen3();
	clrGen4();
	setGen2();
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	if((valBuf & 0x01C0) != 0x0040){
		test_log(ERROR,"RPI_GPIO" ,"RPI gpio 4-3-2 test failed, expected %04x got %04x \n", 0x0040, (valBuf & 0x01C0)); 
		res = -1 ;
	}
	clrGen3();
	clrGen2();
	setGen4();
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	if((valBuf & 0x01C0) != 0x0100){
		test_log(ERROR,"RPI_GPIO", "RPI gpio 4-3-2 test failed, expected %04x got %04x \n", 0x0100, (valBuf & 0x01C0)); 
		res = -1 ;
	}
	closeGPIOs();
	return res ;
}

#endif



int testPMOD12(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = GPIO_TEST1_DIR ;
	valBuf = GPIO_TEST1_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != GPIO_TEST1_1_EXPECTED){
		test_log(ERROR, "PMOD_1_2", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST1_1_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST1_1_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2", "Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_1_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
		}	
		return -1 ;
	}
	valBuf = GPIO_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_2_EXPECTED) ){
		test_log(ERROR, "PMOD_1_2", "Pass 2 : Expected %04x got %04x \n", (GPIO_TEST1_2_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST1_2_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_2_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
		}	 
		return -1 ;
	}

	dirBuf = GPIO_TEST2_DIR ;
	valBuf = GPIO_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_1_EXPECTED)){
		test_log(ERROR, "PMOD_1_2", "Pass 3 : Expected %04x got %04x \n", (GPIO_TEST2_1_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST2_1_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_1_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
		}		 
		return -1 ;
	}
	valBuf = GPIO_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_2_EXPECTED) ){
		test_log(ERROR, "PMOD_1_2", "Pass 4 : Expected %04x got %04x \n", (GPIO_TEST2_2_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST2_2_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_2_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
		}
		return -1 ;
	}
	return 0 ;
}


int testPMOD12OpenTest(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = (unsigned short int)GPIO_TEST1_DIR ;
	valBuf = ((unsigned short int)~GPIO_TEST1_DIR) ; // pulling pins down
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (unsigned short int) (~GPIO_TEST1_DIR)){
		test_log(ERROR, "PMOD_1_2 Open Test", "Pass 1 : Expected %04x got %04x \n", (unsigned short int) (~GPIO_TEST1_DIR), valBuf);
		if((valBuf & 0x00FF) != ((0x00) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2", "Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((0x00) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
		}	
		return -1 ;
	}

	dirBuf = GPIO_TEST2_DIR ;
	valBuf = ~GPIO_TEST2_DIR ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (unsigned short int) (~GPIO_TEST2_DIR)){
		test_log(ERROR, "PMOD_1_2 Open Test", "Pass 2 : Expected %04x got %04x \n", (unsigned short int) (~GPIO_TEST2_DIR), valBuf);
		if((valBuf & 0x00FF) != ((0x00) & 0x00FF)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD1\n");		
		}
		if((valBuf & 0xFF00) != ((0x00) & 0xFF00)){
			test_log(ERROR, "PMOD_1_2","Failure on PMOD2\n");		
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
	if(valBuf != (GPIO_TEST1_1_EXPECTED)){
		test_log(ERROR, "PMOD_3_4", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST1_1_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST1_1_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_1_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
		}		
		return -1 ;
	}
	valBuf = GPIO_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_2_EXPECTED) ){
		test_log(ERROR, "PMOD_3_4", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST1_2_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST1_2_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST1_2_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
		}
		return -1 ;
	}
	dirBuf = GPIO_TEST2_DIR ;
	valBuf = GPIO_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO1DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_1_EXPECTED)){
		test_log(ERROR, "PMOD_3_4", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST2_1_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST2_1_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_1_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
		}		
		return -1 ;
	}
	valBuf = GPIO_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_2_EXPECTED) ){
		test_log(ERROR, "PMOD_3_4", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST2_2_EXPECTED), valBuf);
		if((valBuf & 0x00FF) != ((GPIO_TEST2_2_EXPECTED) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((GPIO_TEST2_2_EXPECTED) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
		}		
		return -1 ;
	}

	return 0 ;
}

int testPMOD34OpenTest(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = (unsigned short int)GPIO_TEST1_DIR ;
	valBuf = ((unsigned short int)~GPIO_TEST1_DIR) ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO1DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (unsigned short int) (~GPIO_TEST1_DIR) ){
		test_log(ERROR, "PMOD_3_4 Open Test", "Pass 1 : Expected %04x got %04x \n", (unsigned short int) ~GPIO_TEST1_DIR, valBuf);
		if((valBuf & 0x00FF) != ((0x00) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((0x00) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
		}		
		return -1 ;
	}
	dirBuf = GPIO_TEST2_DIR ;
	valBuf = ~GPIO_TEST2_DIR ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO1DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO1);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO1);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (unsigned short int) (~GPIO_TEST2_DIR)){
		test_log(ERROR, "PMOD_3_4 Open Test", "Pass 2 : Expected %04x got %04x \n", (unsigned short int) (~GPIO_TEST2_DIR), valBuf);
		if((valBuf & 0x00FF) != ((0x00) & 0x00FF)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD3\n");		
		}
		if((valBuf & 0xFF00) != ((0x00) & 0xFF00)){
			test_log(ERROR, "PMOD_3_4","Failure on PMOD4\n");		
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
	for(i = 0 ; i < 6 ; i ++){
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
		test_log(ERROR, "COM","Write error !, returned %d \n", i);
		return -1 ;
	}
	if((i = wishbone_read((unsigned char *) readVals, 2048, MEM0)) < 2048){
		test_log(ERROR, "COM","Read error !, returned %d \n", i);
		return -1 ;
	}
	for(i = 0; i < 512; i ++){
		if(readVals[i] != writeVals[i]){
			test_log(ERROR, "COM","Corrupted Value @%i\n", i);	
			test_log(ERROR, "COM","Expecting  0x%04x , got 0x%04x \n", writeVals[i], readVals[i]);	 	
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
	test_log(ERROR, "SDRAM","test failed : %d \n", (unsigned int) (buffer[0] & 0x8000 == 0x8000));
	test_log(ERROR, "SDRAM","at address : %08x \n", ((buffer[0] & 0x7FFF) | (buffer[1] << 15)));
	test_log(ERROR, "SDRAM","with pattern : %04x%04x \n", buffer[5], buffer[6]);
	test_log(ERROR, "SDRAM","obtained : %04x%04x \n", buffer[2], buffer[3]);
	return 0 ;
}

int testLVDS(){
        unsigned short int write_val, read_val ;
	unsigned int result = 0 ;
        write_val = 1 << SATA_WRITE_SHIFT ;
        wishbone_write((unsigned char *) &write_val, 2, REG0);
        wishbone_read((unsigned char *) & read_val, 2, REG2);
        read_val = (read_val >> SATA_READ_SHIFT) & 0x01 ;
        if(!read_val){
		test_log(ERROR, "LVDS"," writing 1 reading %u :  \n", (unsigned int) read_val );
		result -- ;   
        }
        write_val = 0;
        wishbone_write((unsigned char *) &write_val, 2, REG0);
        wishbone_read((unsigned char *) &read_val, 2, REG2);
        read_val = (read_val >> SATA_READ_SHIFT) & 0x01 ;
        if(read_val){
		test_log(ERROR, "LVDS"," writing 0 reading %x :  \n", (unsigned int) read_val );
		result -- ;   
        }
        return result ;
}


int test_arduino_port(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	int test_result = 0 ;
	dirBuf = ARD_TEST1_DIR ;
	valBuf = ARD_TEST1_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO2DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST1_DIR)) & ARD_MASK  ;
	if(valBuf != ARD_TEST1_1_EXPECTED){
		test_log(ERROR, "ARDUINO ", "Failure on Arduino connector test");
		test_log(ERROR, "ARDUINO", "Pass 1 : Expected %04x got %04x \n", (ARD_TEST1_1_EXPECTED), valBuf);
		test_result =  -1 ;
	}
	valBuf = ARD_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST1_DIR)) & ARD_MASK  ;
	if(valBuf != (ARD_TEST1_2_EXPECTED) ){
		test_log(ERROR, "ARDUINO ", "Failure on Arduino connector test");
		test_log(ERROR, "ARDUINO", "Pass 2 : Expected %04x got %04x \n", (ARD_TEST1_2_EXPECTED), valBuf); 
		test_result =  -1 ;
	}

	dirBuf = ARD_TEST2_DIR ;
	valBuf = ARD_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO2DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST2_DIR)) & ARD_MASK  ;
	if(valBuf != (ARD_TEST2_1_EXPECTED)){
		test_log(ERROR, "ARDUINO ", "Failure on Arduino connector test");
		test_log(ERROR, "ARDUINO", "Pass 3 : Expected %04x got %04x \n", (ARD_TEST2_1_EXPECTED), valBuf); 
		test_result =  -1 ;
	}
	valBuf = ARD_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST2_DIR)) & ARD_MASK  ;
	if(valBuf != (ARD_TEST2_2_EXPECTED) ){
		test_log(ERROR, "ARDUINO ", "Failure on Arduino connector test");
		test_log(ERROR, "ARDUINO", "Pass 4 : Expected %04x got %04x \n", (ARD_TEST2_2_EXPECTED), valBuf);
		test_result =  -1 ;
	}
	return test_result ;

}



int test_arduino_port_open(){
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	int test_result = 0 ;
	dirBuf = ARD_TEST1_DIR ;
	valBuf = ~(ARD_TEST1_DIR) ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO2DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST1_DIR)) & ARD_MASK  ;
	if(valBuf != (unsigned short int) ((~ARD_TEST1_DIR)&ARD_MASK)){
		test_log(ERROR, "ARDUINO Open Test", "Failure on Arduino connector open test");
		test_log(ERROR, "ARDUINO Open Test", "Pass 1 : Expected %04x got %04x \n", (unsigned short int) ((~ARD_TEST1_DIR)&ARD_MASK), valBuf);
		test_result =  -1 ;
	}

	dirBuf = ARD_TEST2_DIR ;
	valBuf = ~ARD_TEST2_DIR ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO2DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO2);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO2);
	valBuf = (valBuf & (~ARD_TEST2_DIR)) & ARD_MASK  ;
	if(valBuf != (unsigned short int) ((~ARD_TEST2_DIR)&ARD_MASK)){
		test_log(ERROR, "ARDUINO Open Test", "Failure on Arduino connector open test");
		test_log(ERROR, "ARDUINO Open Test", "Pass 2 : Expected %04x got %04x \n", (unsigned short int) ((~ARD_TEST2_DIR)&ARD_MASK), valBuf); 
		test_result =  -1 ;
	}
	return test_result ;

}

int main(int argc, char ** argv){
	char c [10];	
	char * argv2 [3];
	init_test_log();	
	test_log(INFO,"MAIN", "Press Enter to begin testing \n");
	while(fgets(c, 2, stdin) == NULL);
	test_log(INFO, "MAIN","----------------Loading FPGA--------------\n");	
	// load fpga
	system(LOAD_CMD);
	//
	sleep(1);
	test_log(INFO, "MAIN","-----------------Starting Test-------------\n");
	
	#ifdef TEST_COMM
	test_log(INFO, "COM","-----------------Communication Test---------------\n");
	if(testCom() < 0) {
		test_log(ERROR, "COM","Communication test failed \n");	
		close_test_log();
		return -1 ;
	}else{
		test_log(INFO, "COM","Communication test passed \n");	
	}
	#endif
	
	#ifdef TEST_PMOD_1_2
	test_log(INFO, "MAIN","-------------------GPIO Test---------------\n");
	if(testPMOD12() < 0){
		test_log(ERROR, "PMOD_1_2","PMOD1-2 test failed \n");		
	}else{
		test_log(INFO, "PMOD_1_2","PMOD1-2 test passed \n");
	}
	#endif

	#ifdef TEST_PMOD_3_4
	if(testPMOD34() < 0){
		test_log(ERROR, "PMOD_3_4","PMOD3-4 test failed \n");	
	}else{
		test_log(INFO, "PMOD_3_4","PMOD3-4 test passed \n");
	}
	#endif

	#ifdef TEST_ARD
	if(test_arduino_port() < 0){
		test_log(ERROR, "ARDUINO","Arduino connector test failed \n");	
	}else{
		test_log(INFO, "ARDUINO","Arduino connector test passed \n");
	}
	#endif
	
	#ifdef TEST_RPI_GPIO
	if(testRpiGpio() < 0){
		test_log(ERROR, "RPI_GPIO","RPI GPIO test failed \n");	
	}else{
		test_log(INFO, "RPI_GPIO","RPI GPIO connector test passed \n");
	}
	#endif
	
	
	#ifdef TEST_LED
	test_log(INFO, "MAIN","----------------Testing LEDs--------------\n");
	testLED();
	printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	while(fgets(c, 2, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
	//printf("%c \n", c[0]);
	if(c[0] == 'n'){
		test_log(ERROR, "LED","Led test failed \n");	
	}else{
		while(c[0] != 'y'){
			testLED();
			printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
			while(fgets(c, 2, stdin)== NULL) printf("Did the two LED blinked ? (r=retry, y=yes, n=no):");
			if(c[0] == 'n'){
				test_log(ERROR, "LED","Led test failed \n");	
				break ;	
			}
			printf("\n");
		}
		if(c[0] == 'y'){
			test_log(INFO, "LED","Led test passed \n");
		}
	}
	#endif
	
	#ifdef TEST_PB
	printf("\n");
	test_log(INFO, "MAIN","----------------Testing PB--------------\n");
	printf("Click the Push buttons, press enter if nothing happens \n");
	if(testPB() < 0){
		test_log(ERROR, "PB","PB test failed \n");	
	}else{
		test_log(INFO, "PB","PB test passed \n");
	}
	#endif
	
	#ifdef TEST_SW
	test_log(INFO, "MAIN","----------------Testing SW--------------\n");
	printf("Switch the switches, press enter if nothing happens \n");
	if(testSW() < 0){
		test_log(ERROR, "SW","SW test failed \n");	
	}else{
		test_log(INFO, "SW","SW test passed \n");
	}
	#endif

	
	
	#ifdef TEST_SDRAM
	test_log(INFO, "MAIN","----------------Testing SDRAM--------------\n");	
	while(testSdram() > 0) sleep(1);
	if(testSdram() < 0){
		test_log(ERROR, "SDRAM","SDRAM test failed \n");
		getSdramDump();	
	}else{
		test_log(INFO, "SDRAM","SDRAM test passed \n");	
	}
	#endif

	#ifdef TEST_LVDS
	test_log(INFO, "MAIN","----------------Testing LVDS--------------\n");	
	if(testLVDS() < 0){
		test_log(ERROR, "LVDS","LVDS test failed \n");	
	}else{
		test_log(INFO, "LVDS","LVDS test passed \n");	
	}
	test_log(INFO, "MAIN","--------------- End of test ----------------\n");
	#endif

	
	
	#ifdef TEST_OPEN
	test_log(INFO, "MAIN","----------------Starting Open Test--------------\n");
	test_log(INFO, "MAIN","------Remove IOs test-jiigs and then press y key to continue------\n");
	c[0] = 'a' ;	
	while(fgets(c, 2, stdin)== NULL || c[0] != 'y');
	
	#ifdef TEST_PMOD_1_2
	if(testPMOD12OpenTest() < 0){
		test_log(ERROR, "PMOD_1_2 Open","PMOD1-2 Open test failed \n");		
	}else{
		test_log(INFO, "PMOD_1_2 Open","PMOD1-2 Open test passed \n");
	}
	#endif

	#ifdef TEST_PMOD_3_4
	if(testPMOD34OpenTest() < 0){
		test_log(ERROR, "PMOD_3_4 Open","PMOD3-4 Open test failed \n");	
	}else{
		test_log(INFO, "PMOD_3_4 Open","PMOD3-4 Open test passed \n");
	}
	#endif

	#ifdef TEST_ARD
	if(test_arduino_port_open() < 0){
		test_log(ERROR, "ARDUINO Open","Arduino connector Open test failed \n");	
	}else{
		test_log(INFO, "ARDUINO Open","Arduino connector Open test passed \n");
	}
	#endif
	#endif




	close_test_log();
	return 0 ;
	
}
