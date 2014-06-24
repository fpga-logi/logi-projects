CC = gcc


all: test_wishbone

clean:
	rm -f *.a *.o test_wishbone

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) -c wishbone_wrapper.c

test_wishbone : test_wishbone.c wishbone_wrapper.o
	$(CC) -o $@ test_wishbone.c wishbone_wrapper.o
