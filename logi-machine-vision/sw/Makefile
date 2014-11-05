#Compiler to use
CC=gcc
#Compiler Flags
#Linker Flags
CFLAGS = -c
LDFLAGS= -ljpeg -lrt -llogi


all: image_demo

image_demo: image_demo.o jpeg_func.o
	$(CC) -o image_demo image_demo.o jpeg_func.o $(LDFLAGS) 

image_demo.o: image_demo.c
	$(CC) $(CFLAGS) image_demo.c

jpeg_func.o: jpeg_func.c
	$(CC) $(CFLAGS) jpeg_func.c

clean:
	rm -rf *.o image_demo
