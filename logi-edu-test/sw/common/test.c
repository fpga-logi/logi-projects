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


char decode_sseg [] = {0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71};

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


int testIOs(){
	unsigned int error_count = 0 ;
	unsigned short int dirBuf ;
	unsigned short int valBuf ;
	dirBuf = GPIO_TEST1_DIR ;
	valBuf = GPIO_TEST1_1 ;
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != GPIO_TEST1_1_EXPECTED){
		test_log(ERROR, "IO", "Pass 1 : Expected %04x got %04x \n", (GPIO_TEST1_1_EXPECTED), valBuf);
		test_log(ERROR, "IO","Failure\n");
		error_count ++ ;
	}
	valBuf = GPIO_TEST1_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST1_DIR)  ;
	if(valBuf != (GPIO_TEST1_2_EXPECTED) ){
		test_log(ERROR, "IO", "Pass 2 : Expected %04x got %04x \n", (GPIO_TEST1_2_EXPECTED), valBuf);
		test_log(ERROR, "IO","Failure\n"); 
		error_count ++ ;
	}

	dirBuf = GPIO_TEST2_DIR ;
	valBuf = GPIO_TEST2_1 ; 
	wishbone_write((unsigned char *) &dirBuf, 2, GPIO0DIR);
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_1_EXPECTED)){
		test_log(ERROR, "IO", "Pass 3 : Expected %04x got %04x \n", (GPIO_TEST2_1_EXPECTED), valBuf);
		test_log(ERROR, "IO","Failure\n");		 
		error_count ++ ;
	}
	valBuf = GPIO_TEST2_2 ;
	wishbone_write((unsigned char *)&valBuf, 2, GPIO0);
	wishbone_read((unsigned char *)&valBuf, 2, GPIO0);
	valBuf = valBuf & (~GPIO_TEST2_DIR)  ;
	if(valBuf != (GPIO_TEST2_2_EXPECTED) ){
		test_log(ERROR, "IO", "Pass 4 : Expected %04x got %04x \n", (GPIO_TEST2_2_EXPECTED), valBuf);
		test_log(ERROR, "IO","Failure\n");
		error_count ++ ;
	}
	if(error_count > 0) return -1 ;
	return 0 ;
}


int testSSEG(){
	char sseg_buff [6] ;
	unsigned int i ;
	unsigned int count = 0 ;
	while(count < 8){
		sseg_buff[0] = (count & 0x01)<<7 | decode_sseg[count];	
		sseg_buff[1] = (count & 0x01)<<7 | decode_sseg[15 - count];
		sseg_buff[2] = (count & 0x01)<<7 | decode_sseg[count];
		sseg_buff[3] = (count & 0x01)<<7 | decode_sseg[15 - count];
		sseg_buff[4] = decode_sseg[count];
		wishbone_write((unsigned char *) sseg_buff, 6, SSEG_0);
		sleep(1);
		count ++ ;	
	}
	return 0 ;
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
	
	/*
	#ifdef TEST_SOUND
	test_log(INFO, "COM","-----------------Sound Test---------------\n");
	printf("Do you have a sound coming out the audio jack ? (y=yes, n=no):");
	while(fgets(c, 2, stdin) == NULL || (c[0] != 'n' && c[0] != 'y')) printf("Do you have a sound coming out the audio jack ? (y=yes, n=no):");
	if(c[0] == 'n'){
		test_log(ERROR, "SOUND","SOUND test failed \n");	
	}else{
		test_log(INFO, "SOUND","SOUND test passed \n");
	}
	#endif
	*/

	memset(c, 0, 10);
	#ifdef TEST_VGA
	sleep(1);
	test_log(INFO, "COM","-----------------VGA Test---------------\n");
	printf("Do see 8 grayscale bars on the display?\nIf there is any visible color select no(failed)? (y=yes, n=no):");
	while(fgets(c, 2, stdin) == NULL || (c[0] != 'n' && c[0] != 'y')); 
	if(c[0] == 'n'){
		test_log(ERROR, "VGA","VGA test failed \n");	
	}else{
		test_log(INFO, "VGA","VGA test passed \n");
	}
	#endif
	memset(c, 0, 10);
	#ifdef TEST_SSEG
	test_log(INFO, "COM","-----------------SSEG Test---------------\n");
	testSSEG();
	printf("Did the sseg count up/down (in hex)?\n2 segments count up 2 segments count down (y=yes, n=no):");
	while(fgets(c, 2, stdin)== NULL || (c[0] != 'n' && c[0] != 'y')); 
	if(c[0] == 'n'){
		test_log(ERROR, "SSEG","SSEG test failed \n");	
	}else{
		test_log(INFO, "SSEG","SSEG test passed \n");
	}
	#endif

	#ifdef TEST_IO
		if(testIOs() < 0){
			test_log(INFO, "IO","IO test failed \n");
		}else{
			test_log(INFO, "IO","IO test passed \n");
		}		
	#endif




	close_test_log();
	return 0 ;
	
}
