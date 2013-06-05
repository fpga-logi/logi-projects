
from avc_platform import AvcPlatform
from avc_platform import ColorBlob
from waypoint_provider import StaticWayPointProvider
from controllers import BlobTrackingController as Controller

import time

import gps
from gps_service import GpsService
from math import radians, cos, sin, asin, sqrt, atan2 , degrees


STEERING_SERVO = 1 
ESC_SERVO = 0
ESC_ARM_ANGLE = 10.0



def populateSensorMap(robot, gps_service):
	pos = gps_service.getPosition()
	valid, euler, gyro  = robot.getPlatformAttitude()
	sensor_map = {}	
	if valid == 0:
		return sensor_map
	sensor_map = {}
	#sensor_map[IController.imu] = (euler, gyro)
	sensor_map[Controller.gps_key] = gps_service.getPosition()
	sensor_map[Controller.blobs_key] = robot.getBlobPos()
	#TODO: add odometry and blobs
	return sensor_map
	

if __name__ == "__main__":
	blink = 0xAA
	robot = AvcPlatform()
	wp = StaticWayPointProvider()
	gps_service = GpsService()
	controller = Controller()
	gps_service.start()
	robot.resetWatchdog()
	robot.setServoAngle(STEERING_SERVO,45.0)
	robot.setServoAngle(ESC_SERVO,ESC_ARM_ANGLE)
	while True:
		robot.setLeds(blink)
		robot.resetWatchdog()
		target_pos= wp.getCurrentWayPoint()
		current_pos = gps_service.getPosition()
		sensors = populateSensorMap(robot, gps_service)
		if len(sensors) == 0:
			time.sleep(0.1)
			continue	
		cmd = controller.getCommand(sensors)
		if cmd.has_key(Controller.next_waypoint_key) and cmd[Controller.next_waypoint_key] != None and cmd[Controller.next_waypoint_key] == 1:
			wp.getNextWaypoint()
		else:	
			robot.setServoAngle(STEERING_SERVO,cmd[Controller.steering_key])
		blink = ~blink
		time.sleep(0.1)
	robot.setServoAngle(0,0.0)        
	robot.setServoAngle(1,0.0)
	print "Shutdown ESC then quit programm (for safety reason)"
        while True:
		time.sleep(1)	

