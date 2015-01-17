CC = gcc
C_FLAGS = -I/home/debian/logi-tools/c
LD_FLAGS = -lc -ljpeg -L/home/debian/logi-tools/c -llogi

all: grab

clean:
	rm -f *.a *.o grab

grab : grab.c jpeg_func.c
	$(CC) $(C_FLAGS) -o $@ grab.c jpeg_func.c $(LD_FLAGS)

