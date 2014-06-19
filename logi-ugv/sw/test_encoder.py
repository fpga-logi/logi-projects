import logi
import time
import math
from binascii import *
from string import *

logi.logiWrite(0x000D, (0x01, 0x01))
logi.logiWrite(0x000D, (0x00, 0x00))


#calibration procedure:
#1) put the car on the floor and lay a meter or ruler on the side
#2) start the script and push the on a given distance (20cm to 1m)
#3) write-down the tick value at the end of the distance
#4) report the distance in the CALIBRATE_DISTANCE variable, and report the tick count in the CALIBRATE_TICK in the script
#5) run the script again, and verify that the reported distance is fine, you can adjust the CALIBRATE_TICK and CALIBRATE_DISTANCE to give 

CALIBRATE_TICK = 1.0
CALIBRATE_DISTANCE = 1.0 
CONV_FACTOR = CALIBRATE_DISTANCE/CALIBRATE_TICK

while True:
	enc_reg = logi.logiRead(0x000D, 2)
	enc_val = (enc_reg[1] << 8) | enc_reg[0]
	dist = float(enc_val)*CONV_FACTOR
	print "tick : "+str(enc_val)+"tick"
	print "dist : "+str(dist)+"m"
	time.sleep(0.1)
