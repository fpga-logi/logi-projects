Software to work with a 32*32 LED matrix controlled by logipi


0. requirement
-----------------------------------------------------------
liblogipi.so exists in /home/pi/logi-tools/c 
change LD_LIBRARY_PATH to /home/pi/logi-tools/c 
preload the bit stream to the FPGA
 

1. use of test_wishbone
------------------------------------------------------------
tests the communication and speed
make and run


2. use of test_gif
------------------------------------------------------------
please put frames of ppm file into data/
edit the filename in gif.c and make


3. use of one_led and led_white
------------------------------------------------------------
led_white turns the panel to white
one_led lets you control single/continuous leds

4. LED games
-------------------------------------------------------------
Not finished! Will probably open source after finish and consent of the 
author. 
