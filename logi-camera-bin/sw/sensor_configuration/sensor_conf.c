

#include <stdlib.h>
#include <stdio.h>
#include "logilib.h"

#include "ov7670.h"

#define I2C_ADDR 0x1000

void loadSensorConfig(char conf[][2], unsigned int addr, unsigned int conf_size){
	unsigned int i=0 ;
	unsigned short buffer ;
	buffer = 0x4201;
	logi_write((unsigned char *) &buffer, 2, addr+1);
	buffer = 0x4200;
        logi_write((unsigned char *) &buffer, 2, addr+1);
	buffer = 0x0001 ;
	while( conf[i][0] != 0xFF){
		printf("waiting for master not busy \n");
		while((buffer & 0x01) != 0x00 && (buffer & 0x02) != 0x02 ){
			logi_read((unsigned char *)&buffer, 2, addr+1);
			//printf("%x\n", buffer);	
		}
		printf("master free \n");

		//printf("0x%04x\n", buffer);
		if((buffer & 0x02) == 0x02){
			printf("NACK error !\n");
			buffer = 0x4201;
        		logi_write((unsigned char *)&buffer, 2, addr+1);
        		buffer = 0x4200;
        		logi_write((unsigned char *)&buffer, 2, addr+1);
        		buffer = 0x0001 ;
			i -- ;
			continue ;
		}		
		//printf("sending config \n");
		printf("0x%02x , 0x%02x \n", conf[i][0], conf[i][1]);

		buffer = 0x4200;
                logi_write((unsigned char *)&buffer, 2, addr+1); // disable master
		
		buffer = (unsigned short) conf[i][0] ; // write to fifo
		logi_write((unsigned char *)&buffer, 2, addr);
		
		buffer = (unsigned short) conf[i][1] ;
                logi_write((unsigned char *)&buffer, 2, addr);
		
		buffer = 0x4202; 
        	logi_write((unsigned char *)&buffer, 2, addr+1); //enable master
		buffer = 0x0001 ;
		if(i == 0) sleep(1);
		i ++ ;
	}
	
}

void main(void){
	loadSensorConfig(vga_conf, I2C_ADDR, VGA_CONF_SIZE);
}


