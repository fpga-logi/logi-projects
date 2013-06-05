
from datetime import datetime
from datetime import timedelta

import gps_service
import gps

from math import radians, cos, sin, asin, sqrt, atan2 , degrees

MAGN_VAR = 0.0


def eulerToHeading(euler):
	return euler[2] # yaw is on z_axis


def haversineDistanceAndBearing(point_1, point_2):
		#courtesy of http://arduiniana.org/libraries/tinygps/
		lat1 = point_1.lat
		long1 = point_1.lon
		lat2 = point_2.lat
		long2 = point_2.lon
		delta = radians(long1 - long2);
		sdlong = sin(delta);
		cdlong = cos(delta);
		lat1 = radians(lat1);
		lat2 = radians(lat2);
		slat1 = sin(lat1);
		clat1 = cos(lat1);
		slat2 = sin(lat2);
		clat2 = cos(lat2);
		delta = (clat1 * slat2) - (slat1 * clat2 * cdlong);
		x = delta ;
		y = sdlong * clat2;
		delta = sqrt(delta);
		delta += sqrt(clat2 * sdlong);
		delta = sqrt(delta);
		denom = (slat1 * slat2) + (clat1 * clat2 * cdlong);
		delta = atan2(delta, denom);
		distance =  delta * 6372.795;
		x = (180.0 * (atan2(y, x)/pi)) ;
		bearing = (-x + 360)%360 ;
		return (distance, bearing)


class IController:
	
	# sensor map index
	gps_key = "gps"
	imu_key = "imu"
	blobs_key = "blobs"
	odometry_key = "odo"

	# actuator map index
	steering_key = "steer"
	speed_key = "speed"
	next_waypoint_key = "next"


	def getCommand(self, sensor_map):
       		raise NotImplementedError( "Should have implemented this" )

class BearingController(IController):
	

	def getCommand(self, sensor_map):
		
		ctrl = {}	
	
		robot_imu = sensor_map[IController.imu_key]
		robot_gps = sensor_map[IController.gps_key]
		

		distance, bearing = haversineDistanceAndBearing(current_pos, target_pos)
		
		robot_heading = eulerToHeading(robot_imu[1])
		heading_error = heading - (bearing - MAGN_VAR)
	
		ctrl[IController.steering_key] = heading_error
		print "Heading error :", heading_error
		print "Distance to go :", distance
		if distance < 3 or (distance < 5 and abs(heading_error) > 45.0):
			ctrl[IController.next_waypoint_key] = 1
		return ctrl


class BlobTrackingController(IController):
	
	CAMERA_WIDTH = 320
	CAMERA_HEIGHT = 240

	X_GAIN = 0.3
	Y_GAIN = 0.1

	def getCommand(self, sensor_map):
		
		ctrl = {}	
	
		blobs = sensor_map[IController.blobs_key]

		max_blob = None
		for blob in blobs:
			if max_blob == None and  blob.width > 10 and blob.height > 10:
				max_blob = blob
			elif max_blob != None and blob.width > max_blob.width and blob.height > max_blob.height:
				max_blob = blob
		if max_blob == None:
			ctrl[IController.steering_key] = 0.0
			ctrl[IController.speed_key] = 0.0
		else:		
			x = max_blob.x - (self.__class__.CAMERA_WIDTH/2)
			y = max_blob.y - (self.__class__.CAMERA_HEIGHT/2)
			ctrl[IController.steering_key] = x * self.__class__.X_GAIN
			ctrl[IController.speed_key] = y * self.__class__.Y_GAIN
		
		return ctrl
		

def DeadReckogningController(IController):
	
	def __init__(self):
		self.last_time = datetime.now()

	
	def getTimeInterval(self):
		current_time = datetime.now()
		dt = current_time - self.last_time
		self.last_time = current_time 
   		ms = (dt.seconds * 1000) + (dt.microseconds / 1000.0)
		return ms

	def getCommand(self, sensor_map):
		
		ctrl = {}	
	
		robot_imu = sensor_map[self.imu_key]
		robot_gps = sensor_map[self.gps_key]


	
	
