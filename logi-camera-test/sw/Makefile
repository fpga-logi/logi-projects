CC = gcc
LD_FLAGS = -lc -ljpeg

all: test_logi_cam

clean:
	rm -f *.a *.o test_logi_cam

test_logi_cam : test.c wishbone_wrapper.c jpeg_func.c
	$(CC) -D LOGIPI -o $@ test.c wishbone_wrapper.c jpeg_func.c $(LD_FLAGS)

