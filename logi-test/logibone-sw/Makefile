CC = gcc


all: test_logibone

clean:
	rm -f *.a *.o test_logibone

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) -c wishbone_wrapper.c

test_logibone : test_logibone.c wishbone_wrapper.o
	$(CC) -o $@ test_logibone.c wishbone_wrapper.o

