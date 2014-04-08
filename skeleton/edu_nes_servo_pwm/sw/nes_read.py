import sys
sys.path.append("/home/pi/logi-tools/python/") 

import fcntl, os, time, struct, binascii, math
import logi




MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

STEERING_CHANNEL = 0
ESC_CHANNEL = 1



def min_max():
		logi_hal.setServoAngle(0x0010, 0, MIN_ANGLE)
		logi_hal.setServoAngle(0x0010, 1, MIN_ANGLE)
		print "output min: \n", MIN_ANGLE
		time.sleep(1)
		
		logi_hal.setServoAngle(0x0010, 0, MAX_ANGLE)
		logi_hal.setServoAngle(0x0010, 1, MAX_ANGLE)
		print "output max: \n", MAX_ANGLE
		time.sleep(1)
		
	
if __name__ == "__main__":


	nes_val = 0
	nes1_a = 0
	nes1_b = 0
	nes1_up = 0
	nes1_down = 0
	nes1_left = 0
	nes1_right = 0
	nes1_select = 0
	nes1_start = 0

	nes2_a = 0
	nes2_b = 0
	nes2_up = 0
	nes2_down = 0
	nes2_left = 0
	nes2_right = 0
	nes2_select = 0
	nes2_start = 0

	i = MIN_ANGLE;
	mode = 0  # going up
	while True:
	
		#min_max()
		nes_val = logi.logiRead(0x20,2)
		print "nes1_val:	", nes_val[0]
		nes1_a = 		nes_val[0]&0x0001
		nes1_b = 		(nes_val[0]&0x0002)>>1
		nes1_up = 		(nes_val[0]&0x0004)>>2
		nes1_down = 	(nes_val[0]&0x0008)>>3
		nes1_left = 	(nes_val[0]&0x0010)>>4
		nes1_right = 	(nes_val[0]&0x0020)>>5
		nes1_select = 	(nes_val[0]&0x0040)>>6
		nes1_start = 	(nes_val[0]&0x0080)>>7
		print "nes1_a:		", nes1_a
		print "nes1_b:		", nes1_b
		print "nes1_up:	", nes1_up
		print "nes1_down:	", nes1_down
		print "nes1_left:	", nes1_left
		print "nes1_right:	", nes1_right
		print "nes1_select:	", nes1_select
		print "nes1_start:	", nes1_start, "\n"

		
		print "nes2_val:	", nes_val[1]
		nes1_a = 		nes_val[1]&0x0001
		nes1_b = 		(nes_val[1]&0x0002)>>1
		nes1_up = 		(nes_val[1]&0x0004)>>2
		nes1_down = 	(nes_val[1]&0x0008)>>3
		nes1_left = 	(nes_val[1]&0x0010)>>4
		nes1_right = 	(nes_val[1]&0x0020)>>5
		nes1_select = 	(nes_val[1]&0x0040)>>6
		nes1_start = 	(nes_val[1]&0x0080)>>7
		print "nes2_a:		", nes2_a
		print "nes2_b:		", nes2_b
		print "nes2_up:	", nes2_up
		print "nes2_down:	", nes2_down
		print "nes2_left:	", nes2_left
		print "nes2_right:	", nes2_right
		print "nes2_select:	", nes2_select
		print "nes2_start:	", nes2_start, "\n"
		time.sleep(.2)
	