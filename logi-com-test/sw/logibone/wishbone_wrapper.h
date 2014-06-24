#ifndef WISHBONE_WRAPPER_H
#define WISHBONE_WRAPPER_H

int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address);
int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address);

#endif

