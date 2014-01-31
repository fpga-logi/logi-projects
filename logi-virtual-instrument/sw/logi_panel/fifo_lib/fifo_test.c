#include "fifolib.h"
#include <unistd.h>

unsigned char buffer[32*6*2] ;

int main(int argc, char ** argv){
	unsigned int i ;
	if(fifo_open(0) < 0) return -1 ;
	if(fifo_open(1) < 0) return -1 ;
	printf("fifo 0 is %d large and contains %d tokens \n", fifo_getSize(0), fifo_getNbAvailable(0));
	printf("fifo 1 is %d large and contains %d tokens \n", fifo_getSize(1), fifo_getNbAvailable(1));
	/*while(1){
		fifo_reset(1);
		fifo_read(1, buffer, 32*6);
		for(i = 0 ; i < 5 ; i ++){
			unsigned int posx0, posy0, posx1, posy1;
			posy0 = buffer[i*(6)];
			posy0 += (buffer[(i*(6))+1] & 0x03 << 8);
			posx0 = (buffer[(i*(6))+1] & 0xFC >> 2);
			posx0 += (buffer[(i*(6))+2] & 0x03 << 8);

			posy1 = (buffer[i*(6)+2] & 0xFC >> 2);
			posy1 += (buffer[(i*(6))+3] & 0x03 << 8);
			posx1 = (buffer[(i*(6))+3] & 0xFC >> 2);
			posx1 += (buffer[(i*(6))+4] & 0x03 << 8);


			printf("x[%d] = %d, y[%d] = %d \n", i, (posx0 + posx1)/2, i, (posy0 + posy1)/2);
		}
		sleep(1);	
	}*/ //blob_tracking test ...
	fifo_close(1);
	fifo_close(0);
}
