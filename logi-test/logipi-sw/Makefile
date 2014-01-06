CC = gcc


all: test_logipi

clean:
	rm -f *.a *.o test_logipi

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) -c wishbone_wrapper.c

test_logipi : test_logipi.c wishbone_wrapper.o
	$(CC) -o $@ test_logipi.c wishbone_wrapper.o

