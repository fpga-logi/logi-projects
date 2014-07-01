


int wishbone_init(void);
int set_speed(unsigned long speed_arg);
unsigned int wishbone_write(unsigned char * buffer, unsigned int length, unsigned int address);
unsigned int wishbone_read(unsigned char * buffer, unsigned int length, unsigned int address);
