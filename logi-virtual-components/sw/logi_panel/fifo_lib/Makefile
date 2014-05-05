CC = gcc


all: beaglebone_fifo_test rpi_fifo_test

clean:
	rm -f *.a *.o fifo_test

rpi_fifo.o: rpi-fifolib.c
	$(CC) -c $@ rpi-fifolib.c

beaglebone_fifo.o: beaglebone-fifolib.c
	$(CC) -c $@ beaglebone-fifolib.c

beaglebone_fifo_test : fifo_test.c beaglebone-fifolib.o
	$(CC) -o $@ fifo_test.c beaglebone-fifolib.o

rpi_fifo_test : fifo_test.c rpi-fifolib.o
	$(CC) -o $@ fifo_test.c rpi-fifolib.o
