#define RPI
#include "fifolib.h"
#include <linux/types.h>
#include <linux/spi/spidev.h>


#define WR0(a, i)	((a >> 6) & 0x0FF) 
#define WR1(a, i)	(((a << 2) & 0xFC) | (i << 1)) 

#define RD0(a, i)	((a >> 6) & 0x0FF) 
#define RD1(a, i)	(((a << 2) & 0xFC) | 0x01 | (i << 1)) 



int fd ;
unsigned int fifo_size ;
static const char * device = "/dev/spidev0.0";
static unsigned int mode = 0 ;
static unsigned int bits = 8 ;
static unsigned long speed = 32000000UL ;
static unsigned int delay = 0;

static unsigned char com_buffer [FIFO_BLOCK_SIZE + 2] ;


void spi_close(void) ;
int spi_init(void) ;
int spi_transfer(unsigned char * send_buffer, unsigned char * receive_buffer, unsigned int size);
int mark1_write(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc);
int mark1_read(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc);

int spi_init(void){
	int ret ;
	fd = open(device, O_RDWR);
	if (fd < 0){
		printf("can't open device\n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
	if (ret == -1){
		printf("can't set spi mode \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_MODE, &mode);
	if (ret == -1){
		printf("can't get spi mode \n ");
		return -1 ;
	}

	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1){
		printf("can't set bits per word \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
	if (ret == -1){
		printf("can't get bits per word \n");
		return -1 ;
	}

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1){
		printf("can't set max speed hz \n");
		return -1 ;
	}

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret == -1){
		printf("can't get max speed hz \n");
		return -1 ;
	}

	return 1;
}


int spi_transfer(unsigned char * send_buffer, unsigned char * receive_buffer, unsigned int size)
{
	int ret ;
	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)send_buffer,
		.rx_buf = (unsigned long)receive_buffer,
		.len = size,
		.delay_usecs = delay,
		.speed_hz = speed,
		.bits_per_word = bits,
	};

	ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
	if (ret < 1){
		printf("can't send spi message  \n");
		return -1 ;	
	}
	return 0;
}

int mark1_write(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc){
	com_buffer[0] = WR0(add, inc) ;
	com_buffer[1] = WR1(add, inc) ;
	memcpy(&com_buffer[2], data, size);
	return spi_transfer(com_buffer, com_buffer , (size + 2));
	 
}


int mark1_read(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc){
	int ret ;	
	com_buffer[0] = RD0(add, inc) ;
	com_buffer[1] = RD1(add, inc) ;
	ret = spi_transfer(com_buffer, com_buffer , (size + 2));
	memcpy(data, &com_buffer[2], size);
	return ret ;
}


void spi_close(void){
	close(fd);
}


int fifo_open(unsigned char id){
	int ret ;
	if(id >= MAX_FIFO_NB) return -1 ;
	fifo_array[id].id = id ;
	fifo_array[id].address = id * FIFO_SPACING ;
	fifo_array[id].open = -1 ;
	if(fd == 0){
		ret = spi_init();
	}else{
		ret = 1 ;		
	}
	if(ret > 0){
		 fifo_array[id].size = fifo_getSize(id) ;
		 fifo_array[id].open = 1 ;
	}
	return ret ;
}

void fifo_close(unsigned char id){
	fifo_array[id].open = -1 ;
	if(id == 0){
		spi_close();
	}
}

int fifo_write(unsigned char id, unsigned char * data, unsigned int count){
	unsigned int transferred = 0 ;
	unsigned int transfer_size = 0 ;
	unsigned char * src_addr =(unsigned char *) data;
	if(count < FIFO_BLOCK_SIZE){
		transfer_size = count ;
	}else{
		transfer_size = FIFO_BLOCK_SIZE ;
	}
	while(transferred < count){
		while(fifo_getNbFree(id) < transfer_size); 
		mark1_write(fifo_array[id].address,  src_addr, transfer_size, 0);
		src_addr += transfer_size ;
		transferred += transfer_size ;
		if((count - transferred) < FIFO_BLOCK_SIZE){
			transfer_size = count - transferred ;
		}else{
			transfer_size = FIFO_BLOCK_SIZE ;
		}
	}
	return transferred ;
}

int fifo_read(unsigned char id, unsigned char * data, unsigned int count){
	unsigned int transferred = 0 ;
	unsigned int transfer_size = 0 ;
	unsigned char * trgt_addr =(unsigned char *) data;
	if(count < FIFO_BLOCK_SIZE){
		transfer_size = count ;
	}else{
		transfer_size = FIFO_BLOCK_SIZE ;
	}	
	while(transferred < count){
		while(fifo_getNbAvailable(id) < transfer_size); 
		mark1_read(fifo_array[id].address,  trgt_addr, transfer_size, 0);
		trgt_addr += transfer_size ;
		transferred += transfer_size ;
		if((count - transferred) < FIFO_BLOCK_SIZE){
			transfer_size = (count - transferred) ;
		}else{
			transfer_size = FIFO_BLOCK_SIZE ;
		}
	}
	return transferred ;
}

void fifo_reset(unsigned char id){
	unsigned int zero = 0 ;
	unsigned int addA = fifo_array[id].address + FIFO_NB_AVAILABLE_A_OFFSET;
	unsigned int addB = fifo_array[id].address + FIFO_NB_AVAILABLE_B_OFFSET;
	mark1_write(addA,(unsigned char *) &zero, 2, 1);
	mark1_write(addB, (unsigned char *)&zero, 2, 1);
}

unsigned int fifo_getSize(unsigned char id){
	unsigned int add = fifo_array[id].address + FIFO_SIZE_OFFSET ;
	unsigned int fSize = 0 ;
	mark1_read(add, (unsigned char *) &fSize, 2, 0);
	return fSize*2 ;
}

unsigned int fifo_getNbFree(unsigned char id){
	unsigned int add = fifo_array[id].address + FIFO_NB_AVAILABLE_A_OFFSET ;
	unsigned int fFree = 0 ;
	mark1_read(add, (unsigned char *) &fFree, 2, 0);
	fFree = fifo_array[id].size - (fFree*2) ;
	return fFree ;
}


unsigned int fifo_getNbAvailable(unsigned char id){
	unsigned int add = fifo_array[id].address + FIFO_NB_AVAILABLE_B_OFFSET ;
	unsigned int fAvail = 0 ;
	mark1_read(add, (unsigned char *) &fAvail, 2, 0);
	return fAvail*2 ;
}

void fifo_setAddress(unsigned int id, unsigned int address){
	fifo_array[id].address = address;
}

void fifo_setCmdOffset(unsigned int id, unsigned int offset){
	fifo_array[id].cmd_offset = offset;
}


unsigned int direct_write(unsigned int address, unsigned char * buffer, unsigned int length){
	if(fd == 0){
		spi_init();
	}
	return mark1_write(address, buffer, length, 1);
}
unsigned int direct_read(unsigned int address, unsigned char * buffer, unsigned int length){
	if(fd == 0){
		spi_init();
	}
	return mark1_read(address, buffer, length, 1);
}


