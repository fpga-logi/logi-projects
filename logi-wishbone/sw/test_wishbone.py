
import time, math
from logi import *

print "Demo Details:******************************************************************"
print "* The user can modify the .py file to experiment with accessing the FPGA by reading and writing data on the FPGA.  See the Register set defined in the README.TXT file"       
print "* This demo writes values to the FPGA PWM peripherals and increment the duty cycle sinusoidally.  You can see the value output being displayed on LED0"
print "* key CTL C to exit the program"
print "*****************************************************************************"



logiWrite(0x0008, (0x04, 0x00))
logiWrite(0x0009, (0x00, 0x08))
t = 0
while True:
	val = abs(int(0x0800 * math.sin(t)))
	logiWrite(0x000B, ((val & 0x00FF), (val >> 7)))
	time.sleep(0.01)
	t = t + 0.01
