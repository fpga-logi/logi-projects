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
		logi_hal.setServoFailSafePulse(ugv_map.SERVO_0, ESC_CHANNEL, int(pos+128))
	
	def setSteeringFailSafe(self, angle):
		logi_hal.setServoFailSafeAngle(ugv_map.SERVO_0, STEERING_CHANNEL, angle)
	
	def setSteeringAngle(self, angle):
		logi_hal.setServoAngle(ugv_map.SERVO_0, STEERING_CHANNEL, angle)

	def getPushButtons(self):
		return (logi_hal.readRegister(ugv_map.REG_0, 3) & 0x0003)

	def resetWatchdog(self):
		logi_hal.resetWatchdog((ugv_map.WATCH_0))


class SimulatedUgvPlatform(object):
	
	def __init__(self):
		print "initialized"
	
	def setSpeed(self, pos):	
		print "set speed "+str(pos)

	def setSpeedFailSafe(self, pos):	
		print "set speed failsafe "+str(pos)
	
	def setSteeringFailSafe(self, angle):
		print "set steering failsafe "+str(angle)
	
	def setSteeringAngle(self, angle):
		print "set steering "+str(angle)

	def getPushButtons(self):
		return 0x03

	def resetWatchdog(self):
		print "reset watchdog "



if __name__ == "__main__":
	robot = UgvPlatform()
	time.sleep(2)
	robot.setSpeedFailSafe(0)
	robot.setSteeringFailSafe(0.0)
	robot.setSpeed(0)
	robot.resetWatchdog()
	i = 0
	while True:
		robot.resetWatchdog()
		robot.setSteeringAngle(math.sin(i)*35.0)
		print math.sin(i)*35.0
		time.sleep(0.01)
		i =  i + 0.1
		if i > (2*math.pi) :
			i = 0

