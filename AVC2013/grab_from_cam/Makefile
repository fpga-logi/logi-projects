#Compiler to use
CC=gcc
#Compiler Flags
CFLAGS=-c -I../fifo_lib/#-Wall
#Linker Flags
LDFLAGS= -ljpeg -lrt

all: grab_frame

grab_frame: grab_frame.o jpeg_func.o fifolib.o
	$(CC) -o grab_frame grab_frame.o jpeg_func.o ../fifo_lib/rpi-fifolib.o $(LDFLAGS) 

fifolib.o:
	make -C ../fifo_lib

grab_frame.o: grab_frame.c
	$(CC) $(CFLAGS) grab_frame.c

jpeg_func.o: jpeg_func.c
	$(CC) $(CFLAGS) jpeg_func.c

clean:
	rm -rf *o grab_frame
