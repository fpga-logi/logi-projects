CC = gcc
LD_FLAGS = -lc

all: test_logi_edu

clean:
	rm -f *.a *.o test_logi_edu

test_logi_edu : test.c wishbone_wrapper.c
	$(CC) -D LOGIPI -o $@ test.c wishbone_wrapper.c $(LD_FLAGS)
	
