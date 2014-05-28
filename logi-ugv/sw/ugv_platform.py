import sys
sys.path.append("/home/pi/logi-tools/python/") 

import fcntl, os, time, struct, binascii, math
import logi_hal
import ugv_map

MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

STEERING_CHANNEL = 0
ESC_CHANNEL = 1

class UgvPlatform(object):
	
	def __init__(self):
		logi_hal.enableWatchdog((ugv_map.WATCH_0))
	
	def setSpeed(self, pos):	
		logi_hal.setServoPulse(ugv_map.SERVO_0, ESC_CHANNEL, int(pos+128))

	def setSpeedFailSafe(self, pos):	
		logi_hal.setServoFailSafeAngle(ugv_map.SERVO_0, ESC_CHANNEL, pos)
	
	def setSteeringFailSafe(self, angle):
		logi_hal.setServoFailSafeAngle(ugv_map.SERVO_0, STEERING_CHANNEL, angle)
	
	def setSteeringAngle(self, angle):
		logi_hal.setServoAngle(ugv_map.SERVO_0, STEERING_CHANNEL, angle)

	def resetWatchdog(self):
		logi_hal.resetWatchdog((ugv_map.WATCH_0))

if __name__ == "__main__":
	robot = UgvPlatform()
	time.sleep(2)
	robot.setSpeedFailSafe(0.0)
	robot.setSteeringFailSafe(0.0)
	robot.setSpeed(0)
	robot.resetWatchdog()
	i = 0
	while True:
		robot.resetWatchdog()
		robot.setSteeringAngle(math.sin(i)*30.0)
		print math.sin(i)*30.0
		time.sleep(0.1)
		i =  i + 0.1
		if i > (2*math.pi) :
			i = 0

