#!/bin/bash
LD_LIBRARY_PATH=/usr/lib/arm-linux-gnueabihf/
./mjpg_streamer -i "./input_memory.so -i 0 -r 320x240" -o "./output_http.so -w ./www"
