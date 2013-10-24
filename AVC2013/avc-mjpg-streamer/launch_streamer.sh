#!/bin/bash
./mjpg_streamer -i "./input_memory.so -i $1 -r 160x120" -o "./output_http.so -w ./www"
