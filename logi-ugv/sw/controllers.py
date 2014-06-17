
from datetime import datetime
from datetime import timedelta

import socket
import json
import time
from threading import Thread
import math

from math import radians, cos, sin, asin, sqrt, atan2 , degrees

MAGN_VAR = 0.0

ESC_ARM_ANGLE = 0


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
	odometry_key = "odo"

	# actuator map index
	steering_key = "steer"
	speed_key = "speed"
	next_waypoint_key = "next"


	def getCommand(self, sensor_map):
       		raise NotImplementedError( "Should have implemented this" )

	def close(self):
		print "controlled closed"

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

class LocalController(IController):
	
	declination = 8.71 #boulder, 0.083 for Toulouse
	
	
	def __init__(self, home_point):
		self.loc_coord = LocalCoordinates(home_point)


	def getCommand(self, sensor_map):
		
		ctrl = {}	
	
		robot_imu = sensor_map[IController.imu_key]
		robot_gps = sensor_map[IController.gps_key]
		
		
		cur_xy = self.loc_coord.getXYPos(robot_gps)
		target_xy = self.loc_coord.getXYPos(cur_waypoint)
	
		distance = math.sqrt(pow(cur_xy['x']-target_xy['x'] , 2)+pow(cur_xy['y']-target_xy['y'], 2))						

		bearing = asin(fabs(cur_xy['y']-target_xy['y'])/distance)
		bearing = bearing * (360.0/(2*math.pi)) # radian to degree
	
		robot_heading = eulerToHeading(robot_imu[1])
		heading_error = heading - (bearing - declination)
	
		ctrl[IController.steering_key] = heading_error
		print "Heading error :", heading_error
		print "Distance to go :", distance
		if distance < 3 or (distance < 5 and abs(heading_error) > 45.0):
			ctrl[IController.next_waypoint_key] = 1
		return ctrl



class BlobTrackingController(IController):
	
	CAMERA_WIDTH = 320
	CAMERA_HEIGHT = 240

	X_GAIN = 0.5
	Y_GAIN = 0.1



	def __init__(self):
		self.last_x_command = None
		self.last_y_command = None

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
			if self.last_x_command != None and self.last_y_command != None:
				x_cmd = (x * self.__class__.X_GAIN)*0.8 + self.last_x_command*0.2 # low pass filter to avoid high jittering
				y_cmd = (y * self.__class__.Y_GAIN)*0.8 + self.last_y_command*0.2
			else:
				x_cmd = (x * self.__class__.X_GAIN)
				y_cmd = (y * self.__class__.Y_GAIN)
			ctrl[IController.steering_key] = x_cmd
			ctrl[IController.speed_key] = y_cmd
			self.last_x_command = x_cmd
			self.last_y_command = y_cmd
		return ctrl
		

class PathController(IController):
	
	def __init__(self):
		self.last_time = datetime.now()
		self.cumulated_time = 0.0
		self.path_index = 0
		self.path = []
		self.path.append((30.0, 20000))
		self.path.append((90.0, 2000))
		self.path.append((0.0, 2000))
		self.path.append((40.0, 2000))
	
	def getTimeInterval(self):
		current_time = datetime.now()
		dt = current_time - self.last_time
		self.last_time = current_time 
   		ms = (dt.seconds * 1000) + (dt.microseconds / 1000.0)
		return ms

	def getCommand(self, sensor_map):
		
		ctrl = {}	
		interval = self.getTimeInterval()
		robot_imu = sensor_map[self.imu_key]
		self.cumulated_time = self.cumulated_time + interval
		if self.cumulated_time > self.path[self.path_index][1]:
			self.cumulated_time = 0
			self.path_index	= self.path_index + 1
			print "Next heading"
		if self.path_index >= len(self.path):
			return None
		heading = robot_imu[1][2]
		heading_error = self.path[self.path_index][0] - heading
		print "heading: "+str(heading)+" error : "+str(heading_error)
		ctrl[IController.steering_key] = heading_error 
		ctrl[IController.speed_key] = 25
		return ctrl


class EthernetController(IController, Thread):
	
	def __init__(self):
		Thread.__init__(self)
		self.last_time = datetime.now()
		self.cumulated_time = 0.0
		self.path_index = 0
		self.cmd = []
		self.serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		#self.serversocket.close()
		self.serversocket.bind((socket.gethostname(), 2045))
		self.start()
		
	def stop(self):
        	self._Thread__stop()

	def run(self):
		while True:		
			self.serversocket.listen(5)
			conn,addr = self.serversocket.accept() #accept the connection
			print '...connected!'
			init = 0
			done = 1
			c = conn.recv(1)
			while c != '':
				if c == '{' :
					json_buffer = c
					init = 1
					done = 0
				elif init == 1 and c == '}' :
					json_buffer = json_buffer + c
					init = 0
					done = 1
				elif init == 1 :
					json_buffer = json_buffer + c
				
				if done == 1:
					print json_buffer
					json_obj = json.loads(json_buffer)
					if not json_obj.has_key('time'):
						json_obj['time'] = 0.0
					if not json_obj.has_key('speed'):
						json_obj['speed'] = 0
					if not json_obj.has_key('steer'):
						json_obj['steer'] = 0.0
					self.cmd.append(json_obj)
					print json_obj
					done = 0
				time.sleep(0.01)
				c = conn.recv(1)
			conn.close()	
	
	def getTimeInterval(self):
		current_time = datetime.now()
		dt = current_time - self.last_time
		self.last_time = current_time 
   		ms = (dt.seconds * 1000) + (dt.microseconds / 1000.0)
		return ms

	def getCommand(self, sensor_map):
		ctrl = {}
		interval = self.getTimeInterval()
		if len(self.cmd) == 0 :
			ctrl[IController.speed_key] = ESC_ARM_ANGLE
			ctrl[IController.steering_key] = 0.0
			self.cumulated_time = 0
			return ctrl
		print self.cumulated_time
		self.cumulated_time = self.cumulated_time + interval
		print self.cumulated_time
		if self.cumulated_time > self.cmd[0]['time']:
			self.cumulated_time = 0
			ctrl[IController.speed_key] = self.cmd[0]['speed']+ESC_ARM_ANGLE
			ctrl[IController.steering_key] = self.cmd[0]['steer']
			self.cmd.pop(0)
			print "Next Cmd"
		else:
			ctrl[IController.steering_key] = self.cmd[0]['steer']
			ctrl[IController.speed_key] = self.cmd[0]['speed']+ESC_ARM_ANGLE
		return ctrl

	def close(self):
		self.serversocket.close()
		self._Thread__stop()
	
	
