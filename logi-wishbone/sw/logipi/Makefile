CC = gcc


all: read_wishbone write_wishbone test_wishbone

clean:
	rm -f *.a *.o write_wishbone read_wishbone test_wishbone

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) -c wishbone_wrapper.c

read_wishbone : read_wishbone.c wishbone_wrapper.o
	$(CC) -o $@ read_wishbone.c wishbone_wrapper.o

write_wishbone : write_wishbone.c wishbone_wrapper.o
	$(CC) -o $@ write_wishbone.c wishbone_wrapper.o

test_wishbone : test_wishbone.c wishbone_wrapper.o
	$(CC) -o $@ test_wishbone.c wishbone_wrapper.o
