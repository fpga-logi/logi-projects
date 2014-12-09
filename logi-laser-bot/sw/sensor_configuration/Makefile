
CC = gcc
CFLAGS = -I/home/debian/logi-tools/c
LFLAGS = -llogi


all : sensor_conf

clean :
	rm *.o sensor_conf

sensor_conf : sensor_conf.o
	$(CC) -o sensor_conf sensor_conf.o $(LFLAGS)
 
sensor_conf.o : sensor_conf.c
	$(CC) $(CFLAGS) -c sensor_conf.c

