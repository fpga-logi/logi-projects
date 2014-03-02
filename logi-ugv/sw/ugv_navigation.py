
from avc_platform import AvcPlatform
from avc_platform import ColorBlob
from waypoint_provider import StaticWayPointProvider
from controllers import EthernetController as Controller

import time

import gps
from gps_service import GpsService
from math import radians, cos, sin, asin, sqrt, atan2 , degrees


STEERING_SERVO = 1 
ESC_SERVO = 0
ESC_ARM_ANGLE = -15.0



def populateSensorMap(robot, gps_service):
	#pos = gps_service.getPosition()
	#valid, euler, gyro  = robot.getPlatformAttitude()
	#print euler
	sensor_map = {}
	sensor_map[Controller.imu_key] = (euler, gyro)
	sensor_map[Controller.gps_key] = gps_service.getPosition()
	sensor_map[Controller.blobs_key] = robot.getBlobPos()
	#TODO: add odometry and blobs
	return sensor_map
	

if __name__ == "__main__":
	blink = 0xAA
	robot = AvcPlatform()
	#robot.setColorLut('lut_file.lut')
	#robot.initImu('accelcal.txt', 'magcal.txt')
	wp = StaticWayPointProvider()
	#gps_service = GpsService()
	controller = Controller()
	#gps_service.start()
	robot.setServoFailSafe(ESC_SERVO, ESC_ARM_ANGLE)
	robot.setServoFailSafe(STEERING_SERVO, 0.0)
	robot.resetWatchdog()
	robot.setServoAngle(STEERING_SERVO,0.0)
	robot.setServoAngle(ESC_SERVO,ESC_ARM_ANGLE)
	try:
		while True:
			robot.setLeds(blink)
			robot.resetWatchdog()
			#target_pos= wp.getCurrentWayPoint()
			#current_pos = gps_service.getPosition()
			#sensors = populateSensorMap(robot, gps_service)
			sensors = {}
			#if len(sensors) == 0:
			#	time.sleep(0.1)
			#	continue	
			cmd = controller.getCommand(sensors)
			if cmd == None:
				break
			print str(cmd)
			if cmd.has_key(Controller.next_waypoint_key) and cmd[Controller.next_waypoint_key] != None and cmd[Controller.next_waypoint_key] == 1:
				wp.getNextWaypoint()
			else:	
				robot.setServoAngle(STEERING_SERVO,cmd[Controller.steering_key])
				robot.setServoAngle(ESC_SERVO,min(cmd[Controller.speed_key], 20.0))
			blink = ~blink
			time.sleep(0.10)
	except KeyboardInterrupt:
    		controller.close()
		exit()

	robot.setServoAngle(0,0.0)        
	robot.setServoAngle(1,0.0)
	print "Shutdown ESC then quit programm (for safety reason)"
        while True:
		time.sleep(1)	

