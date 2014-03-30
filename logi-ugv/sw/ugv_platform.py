import sys
sys.path.append("/home/pi/logi-tools/python/logi_hal") 

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
		logi_hal.enableWatchdog((ugv_map.Watch_0)
	
	def setSpeed(self, pos):	
		logi_hal.setServoPulse(ugv_map.Servo_0, ESC_CHANNEL, pos)

	def setSpeedFailsafe(self, pos):	
		logi_hal.setServoFailSafeAngle(ugv_map.Servo_0, ESC_CHANNEL, pos)
	
	def setSteeringFailSafeAngle(self, angle):
		logi_hal.setServoFailSafeAngle(ugv_map.Servo_0, STEERING_CHANNEL, angle)
	
	def setSteeringAngle(self, angle):
		logi_hal.setServoAngle(ugv_map.Servo_0, STEERING_CHANNEL, angle)

	def resetWatchdog(self):
		logi_hal.resetWatchdog((ugv_map.Watch_0)

if __name__ == "__main__":
	robot = UgvPlatform()
	time.sleep(2)
	robot.setServoAngle(1, 0.0)
	robot.setServoAngle(0, 0.0)
	robot.resetWatchdog()
	i = 0
	while True:
		robot.resetWatchdog()
		robot.setServoAngle(0, math.sin(i)*0.45)
		robot.setServoAngle(1, math.sin(i)*0.45)
		time.sleep(0.01)
		i =  i + 0.1
		if i > math.pi :
			i = 0

