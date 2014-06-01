
from ugv_platform import UgvPlatform
from waypoint_provider import StaticWayPointProvider
from controllers import EthernetController as Controller

import mpu9150
import time

threads = []

from gps_service import GpsService
from math import radians, cos, sin, asin, sqrt, atan2 , degrees

ESC_ARM_ANGLE = 0.0

def populateSensorMap(robot, gps_service):
	#pos = gps_service.getPosition()
	valid = mpu9150.mpuRead()
	if valid >= 0:
		euler =  mpu9150.getFusedEuler()
		gyro = mpu9150.getRawGyro()
	else:
		euler = {0, 0, 0}
		gyro = {0, 0, 0}
	sensor_map = {}
	sensor_map[Controller.imu_key] = (valid, euler, gyro)
	sensor_map[Controller.gps_key] = gps_service.getPosition()
	#TODO: add odometry and blobs
	return sensor_map
	

def nav_loop():
	robot = UgvPlatform()
	#robot.setColorLut('lut_file.lut')
	#robot.initImu('accelcal.txt', 'magcal.txt')
	mpu_valid = -1
	print "waiting for GPS fix"
	gps_service = GpsService()
	current_pos = gps_service.getPosition()
	while not current_pos.valid:
		time.sleep(1)
		current_pos = gps_service.getPosition()
		print current_pos.valid
	while mpu_valid < 0:
		time.sleep(1.0)
		mpu_valid = mpu9150.mpuInit(1, 10, 4)
	print mpu_valid
	mpu9150.setMagCal('./magcal.txt')
	mpu9150.setAccCal('./accelcal.txt')
	#time.sleep(4)
	wp = StaticWayPointProvider()
	controller = Controller()
	threads.append(controller)
	#gps_service.start()
	robot.setSteeringFailSafe(0.0)
	robot.setSpeedFailSafe(ESC_ARM_ANGLE)
	robot.resetWatchdog()
	robot.setSteeringAngle(0.0)
	robot.setSpeed(0)
	while True:
		robot.resetWatchdog()
		target_pos= wp.getCurrentWayPoint()
		sensors = populateSensorMap(robot, gps_service)
		current_pos = sensors[Controller.gps_key]
		imu_sample = sensors[Controller.imu_key]
		if imu_sample[0] < 0 :
			time.sleep(0.05)
			continue
		#print "lat : "+str(current_pos.lat)+" lon :"+str(current_pos.lon)+"imu:"+str(imu_sample)	
#		continue
		cmd = controller.getCommand(sensors)
		if cmd == None:
			break
		print str(cmd)
		if cmd.has_key(Controller.next_waypoint_key) and cmd[Controller.next_waypoint_key] != None and cmd[Controller.next_waypoint_key] == 1:
			wp.getNextWaypoint()
		else:	
			robot.setSteeringAngle(cmd[Controller.steering_key])
			robot.setSpeed(cmd[Controller.speed_key])
		time.sleep(0.100)
		robot.setSteeringAngle(0.0)        
	robot.setSpeed(0)
	print "Shutdown ESC then quit programm (for safety reason)"
        while True:
		time.sleep(1)	

if __name__ == "__main__":
	try:
		nav_loop()
	except KeyboardInterrupt:
		for t in threads:
			t.close()
		print "dying !"
		exit()
