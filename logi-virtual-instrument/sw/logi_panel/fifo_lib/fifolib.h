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

#define LOGIBONE_FIFO_IOC_MAGIC 'p'
#define LOGIBONE_FIFO_RESET _IO(LOGIBONE_FIFO_IOC_MAGIC, 0)
#define LOGIBONE_FIFO_PEEK _IOR(LOGIBONE_FIFO_IOC_MAGIC, 1, short)
#define LOGIBONE_FIFO_NB_FREE _IOR(LOGIBONE_FIFO_IOC_MAGIC, 2, short)
#define LOGIBONE_FIFO_NB_AVAILABLE _IOR(LOGIBONE_FIFO_IOC_MAGIC, 3, short)
#define LOGIBONE_FIFO_SIZE _IOR(LOGIBONE_FIFO_IOC_MAGIC, 4, short)
#define LOGIBONE_FIFO_MODE _IO(LOGIBONE_FIFO_IOC_MAGIC, 5)
#define LOGIBONE_DIRECT_MODE _IO(LOGIBONE_FIFO_IOC_MAGIC, 6)

#ifdef RPI
#define FIFO_BASE_ADDR	 0x00
#define FIFO_CMD_OFFSET  4
#define FIFO_SIZE_OFFSET	(FIFO_CMD_OFFSET)
#define FIFO_NB_AVAILABLE_A_OFFSET	(FIFO_CMD_OFFSET + 1)
#define FIFO_NB_AVAILABLE_B_OFFSET	(FIFO_CMD_OFFSET + 2)
#define FIFO_PEEK_OFFSET	(FIFO_CMD_OFFSET + 3)
#define FIFO_READ_OFFSET	0
#define FIFO_WRITE_OFFSET	0
#define FIFO_BLOCK_SIZE	4094  //max spi byte per read on raspi
#define FIFO_SPACING 8
#else
#define FPGA_BASE_ADDR	0x1000000
#define FIFO_BASE_ADDR   0x00
#define FIFO_CMD_OFFSET  512
#define FIFO_SIZE_OFFSET        (FIFO_CMD_OFFSET)
#define FIFO_NB_AVAILABLE_A_OFFSET      (FIFO_CMD_OFFSET + 1)
#define FIFO_NB_AVAILABLE_B_OFFSET      (FIFO_CMD_OFFSET + 2)
#define FIFO_PEEK_OFFSET        (FIFO_CMD_OFFSET + 3)
#define FIFO_READ_OFFSET        0
#define FIFO_WRITE_OFFSET       0
#define FIFO_BLOCK_SIZE 1024  //512 * 16 bits
#define FIFO_SPACING 1024
#endif

#define MAX_FIFO_NB 5


#ifndef FIFO_LIB_H
#define FIFO_LIB_H

enum fifo_type{
	user_space,
	kernel_module
};

struct _fifo{
	int id;
	enum fifo_type type ;
	char open ;
	unsigned int address;
	unsigned int cmd_offset;
	unsigned int size ;
};

struct _fifo fifo_array [MAX_FIFO_NB] ;

int fifo_open(unsigned char id);
void fifo_close(unsigned char id);
int fifo_write(unsigned char id, unsigned char * data, unsigned int count);
int fifo_read(unsigned char id, unsigned char * data, unsigned int count);
unsigned int fifo_getSize(unsigned char id);
void fifo_reset(unsigned char id);
unsigned int fifo_getNbFree(unsigned char id);
unsigned int fifo_getNbAvailable(unsigned char id);
void fifo_setAddress(unsigned int id, unsigned int address);
void fifo_setCmdOffset(unsigned int id, unsigned int offset);
unsigned int direct_write(unsigned int address, unsigned char * buffer, unsigned int length);
unsigned int direct_read(unsigned int address, unsigned char * buffer, unsigned int length);

#endif

