CC = gcc
LD_FLAGS = -lc

all: test_logipi test_logibone

clean:
	rm -f *.a *.o test_logipi test_logibone

test_logipi : test.c wishbone_wrapper.c
	$(CC) -D LOGIPI -o $@ test.c wishbone_wrapper.c $(LD_FLAGS)

test_logibone : test.c wishbone_wrapper.c
	$(CC) -D LOGIBONE -o $@ test.c wishbone_wrapper.c $(LD_FLAGS)
