#Compiler to use
CC=gcc
#Compiler Flags
CFLAGS=-c -I/home/ubuntu/logi-tools/c
#Linker Flags
LDFLAGS= -ljpeg -lrt

LOGI_TOOLS=~/logi-tools/

all: logibone_demo

logibone_demo: image_demo.o jpeg_func.o
	$(CC) -o logibone_demo image_demo.o jpeg_func.o $(LOGI_TOOLS)/c/logibonelib.o $(LDFLAGS) 

image_demo.o: image_demo.c
	$(CC) $(CFLAGS) image_demo.c

jpeg_func.o: jpeg_func.c
	$(CC) $(CFLAGS) jpeg_func.c

clean:
	rm -rf *o logibone_demo
