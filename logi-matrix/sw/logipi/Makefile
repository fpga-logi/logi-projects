#Xiaofan Li
#Summer 2014


CC=gcc
CFLAGS=-g#-std=c99 -Wall -Wextra -O2
SHARE_PATH=/home/pi/logi-tools/c


all: test_wishbone test_gif led_white one_led gif_4up led_white_4up

wishbone_wrapper.o: wishbone_wrapper.c
	$(CC) $(CFLAGS) -c $^

libppm.o: libppm.c
	$(CC) $(CFLAGS) -c $^

test_wishbone: test_wishbone.c wishbone_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^

test_gif: libppm.o wishbone_wrapper.o gif.c
	$(CC) $(CFLAGS) -o $@ $^

gif_4up: libppm.o wishbone_wrapper.o gif_4up.c
	$(CC) $(CFLAGS) -o $@ $^

picture: picture.c
	$(CC) $(CFLAGS) -I$(SHARE_PATH) -L$(SHARE_PATH) -o $@ $^ -llogipi

led_white: led_white.c wishbone_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^

led_white_4up: led_white_4up.c wishbone_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^

one_led: one_led.c wishbone_wrapper.o
	$(CC) $(CFLAGS) -o $@ $^


clean:
	rm -rf *.o test_wishbone test_gif one_led led_white gif_4up led_white_4up

