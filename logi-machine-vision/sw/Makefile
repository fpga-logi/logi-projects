#Compiler to use
CC=gcc
#Compiler Flags
#Linker Flags
CFLAGS = -c
LDFLAGS= -ljpeg -lrt -llogi


all: logibone_demo

logibone_demo: image_demo.o jpeg_func.o
	$(CC) -o logibone_demo image_demo.o jpeg_func.o $(LDFLAGS) 

image_demo.o: image_demo.c
	$(CC) $(CFLAGS) image_demo.c

jpeg_func.o: jpeg_func.c
	$(CC) $(CFLAGS) jpeg_func.c

clean:
	rm -rf *.o logibone_demo
