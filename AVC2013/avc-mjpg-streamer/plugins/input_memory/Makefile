###############################################################
#
# Purpose: Makefile for "M-JPEG Streamer"
# Author.: Tom Stoeveken (TST)
# Version: 0.3
# License: GPL
#
###############################################################

CC = gcc

FIFO_LIB_DIR = /root/fifo_lib

OTHER_HEADERS = ../../mjpg_streamer.h ../../utils.h ../output.h ../input.h $(FIFO_LIB_DIR)/fifolib.h

CFLAGS += -O2 -DLINUX -D_GNU_SOURCE -Wall -shared -fPIC
#CFLAGS += -DDEBUG
LFLAGS += -lpthread -ldl -ljpeg -lm

all: input_memory.so

clean:
	rm -f *.a *.o core *~ *.so *.lo

input_memory.so: $(OTHER_HEADERS) input_memory.c jpeg_func.c $(FIFO_LIB_DIR)/rpi-fifolib.c
	$(CC) $(CFLAGS) -I$(FIFO_LIB_DIR) -o $@ input_memory.c jpeg_func.c $(FIFO_LIB_DIR)/rpi-fifolib.c

