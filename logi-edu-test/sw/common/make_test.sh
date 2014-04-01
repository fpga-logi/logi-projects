#!/bin/sh

mkdir /home/pi/tests_log
make clean
make 
sudo ./test_logi_edu
