
#ifdef LOGIPI
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

static unsigned char com_buffer [4096] ;


void spi_close(void) ;
int spi_init(void) ;
int spi_transfer(unsigned char * send_buffer, unsigned char * receive_buffer, unsigned int size);
int logipi_write(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc);
int logipi_read(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc);

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

int logipi_write(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc){
	com_buffer[0] = WR0(add, inc) ;
	com_buffer[1] = WR1(add, inc) ;
	memcpy(&com_buffer[2], data, size);
	return spi_transfer(com_buffer, com_buffer , (size + 2));
}


int logipi_read(unsigned int add, unsigned char * data, unsigned int size, unsigned char inc){
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


unsigned int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0, count = 0 ;
	if(fd == 0){
		spi_init();
	}
	while(count < length){
                tr_size = (length-count) < 4094 ? (length-count) : 4094 ;
		if(logipi_write(((address+count)), &buffer[count], tr_size, 1) < 0) return 0;
		count = count + tr_size ;
        }

	return count ;
}
unsigned int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0, count = 0 ;
	if(fd == 0){
		spi_init();
	}
	while(count < length){
		tr_size = (length-count) < 4094 ? (length-count) : 4094 ;
		if(logipi_read(((address+count)), &buffer[count], tr_size, 1) < 0) return 0 ;
		count = count + tr_size ;
	}
	return count ;
}

#endif


#ifdef LOGIBONE
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
//#include <linux/ioctl.h>
#include <sys/ioctl.h>

int fd ;

void logibone_init(){
	fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
}

unsigned int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0;
	unsigned int count = 0 ;
	if(fd == 0){
		logibone_init();
	}
	count = pwrite(fd, buffer, length, address);
	return count ;
}
unsigned int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address){
	unsigned int tr_size = 0;
	unsigned int count = 0 ;
	if(fd == 0){
		logibone_init();
	}
	count = pread(fd, buffer, length, address);
	return count ;
}

#endif
