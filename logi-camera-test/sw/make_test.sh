#!/bin/sh
mkdir /home/pi/tests_log
sudo apt-get install libjpeg8-dev fbi
make clean
make 
sudo ./test_logi_cam
