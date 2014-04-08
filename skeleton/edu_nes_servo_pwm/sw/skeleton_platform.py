import sys
sys.path.append("/home/pi/logi-tools/python/") 

import fcntl, os, time, struct, binascii, math
import logi_hal
import skeleton_map

#GPIO_0 	= 0x0000
#pwm 	= 	0x0020


MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

STEERING_CHANNEL = 0
ESC_CHANNEL = 1

#class UgvPlatform(object):
	
#	def __init__(self):
#		logi_hal.enableWatchdog((ugv_map.Watch_0)
#	
#	def setSpeed(self, pos):	
#		logi_hal.setServoPulse(ugv_map.Servo_0, ESC_CHANNEL, pos)
#
#	def setSpeedFailsafe(self, pos):	
#		logi_hal.setServoFailSafeAngle(ugv_map.Servo_0, ESC_CHANNEL, pos)
#	
##	def setSteeringFailSafeAngle(self, angle):
#		logi_hal.setServoFailSafeAngle(ugv_map.Servo_0, STEERING_CHANNEL, angle)
#	
##	def setSteeringAngle(self, angle):
##		logi_hal.setServoAngle(ugv_map.Servo_0, STEERING_CHANNEL, angle)
#
#	def resetWatchdog(self):
#		logi_hal.resetWatchdog((ugv_map.Watch_0)

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
	#	robot = UgvPlatform()
	#	time.sleep(2)
	#	robot.setServoAngle(1, 0.0)
	#	robot.setServoAngle(0, 0.0)
	#	robot.resetWatchdog()


	i = MIN_ANGLE;
	mode = 0  # going up
	while True:
	
		min_max()
	
	
		#output to multiple bits on the servo module
		# for j in range(0,1):
			# logi_hal.setServoAngle(0x0010, j, i)
			# print "address bit: ",j," angle: ", i	
		#reset the angle once max is reached
		# i = i + 1
		# if i >= MAX_ANGLE:
			# i=MIN_ANGLE
		# time.sleep(0.01)	
		
				
		#original code
		#setServoAngle(0, math.sin(i)*0.45)
		#robot.setServoAngle(1, math.sin(i)*0.45)
		#time.sleep(0.01)
		#i =  i + 0.1
		#if i > math.pi :
		#	i = 0
		
		#		robot.resetWatchdog()
		#		robot.setServoAngle(0, math.sin(i)*0.45)
		#		robot.setServoAngle(1, math.sin(i)*0.45)


