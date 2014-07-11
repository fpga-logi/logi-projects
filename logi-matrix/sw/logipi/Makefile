#Xiaofan Li
#Summer 2014


CC=gcc
CFLAGS=#-std=c99 -Wall -Wextra -O2
SHARE_PATH="/home/pi/logi-tools/c"



all: test_wishbone test_gif

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) $(CFLAGS) -c $^

libppm.o: libppm.c
	$(CC) $(CFLAGS) -c $^

test_wishbone: test_wishbone.c wishbone_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^

test_gif: libppm.o gif.c
	$(CC) $(CFLAGS) -o $@ $^

picture: picture.c
	$(CC) $(CFLAGS) -I$(SHARE_PATH) -L$(SHARE_PATH) -o $@ $^ -llogipi

clean:
	rm -rf *.o test_wishbone test_gif

