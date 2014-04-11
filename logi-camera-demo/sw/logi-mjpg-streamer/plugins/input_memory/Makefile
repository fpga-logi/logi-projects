###############################################################
#
# Purpose: Makefile for "M-JPEG Streamer"
# Author.: Tom Stoeveken (TST)
# Version: 0.3
# License: GPL
#
###############################################################

CC = gcc

OTHER_HEADERS = ../../mjpg_streamer.h ../../utils.h ../output.h ../input.h wishbone_wrapper.h

CFLAGS += -O2 -DLINUX -D_GNU_SOURCE -DLOGIBONE -Wall -shared -fPIC
#CFLAGS += -DDEBUG
LFLAGS += -lpthread -ldl -ljpeg -lm

all: input_memory.so

clean:
	rm -f *.a *.o core *~ *.so *.lo

input_memory.so: $(OTHER_HEADERS) input_memory.c jpeg_func.c wishbone_wrapper.c
	$(CC) $(CFLAGS) -o $@ input_memory.c jpeg_func.c wishbone_wrapper.c $(LFLAGS)

