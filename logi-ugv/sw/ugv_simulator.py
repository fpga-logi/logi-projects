
import numpy

from path_tracking_service import PurePursuit as TrackingService
from state_estimate_service import RobotState


from gps_service import GpsService
from math import radians, cos, sin, asin, sqrt, atan2 , degrees

CONTROL_RATE = 50
TRACKER_RATE = 1
MAX_SPEED_MS = 10.0 # 10m/s is max speed (36km/h), this parameter must be adjsuted depending on required agressivity
WHEEL_BASE = 0.30 # distance between front and rear axle
DT = 0.020
def speedFromSteering(steering):
	speed = MAX_SPEED_MS * cos(steering) # need to adjusted ... 
	return speed


class UgvModel():
	
	def __init__:
		self.steering = 0.0
		self.speed = 0.0
		self.heading = 180.0
		self.encoder_period = 32768
		self.x = 0.0
		self.y = 0.0
	
	def setSteeringAngle(self, angle):
		self.steering = angle	
	def setSpeed(self, speed):
		self.speed = speed
		
	def stepSim(self, dt):
		
		#if steering = 0, move forward otherwise compute angular speed and compute robot motion based on steering curvature
		# compute new position
		#1/r= sin(a/n)/s for automotive where s is wheel base (distance between rear and front wheels, n steering ratio, a steering wheel angle, translate into 1/r = sin(steering_angle)/s and 1/r is curvature
		
		
		# compute angular speed
		# tetha' * R = speed
		# tetha' = speed /R
		# cos(steering) = 1/(2R) #may be totally off ...
		# R = 1/(2*cos(steering))
		# compute change in heading
		# y increment based on steering and speed
		# x increment based on steering and speed		
			
		self.x = self.x + 
		self.y = self.y + 		

		
	
	def getXYPosition(self):
		
	
	def getEncoderPeriod(self):
		
	
	def getGyro(self):
		return (0.0, 0.0, 0.0)
	
	def getEuler(self):
		return (0.0, 0.0, random.normal(loc=self.heading, scale=1.0))
		

	def resetWatchdog(self):
		return 0
		

def populateSensorMap(robot, gps_service):
	pos = robot.getPosition()
	sensor_map = {}
	sensor_map[Controller.imu_key] = (1, robot.getEuler(), robot.getGyro())
	sensor_map[Controller.gps_key] = pos
	sensor_map[Controller.speed] = pos
	return sensor_map
	

def nav_loop():
	robot = UgvModel()
	state = RobotState()
	path_tracker = PurePursuit()
	wp = WayPointProvider() # use whatever WaypointProvider
	mpu_valid = -1
	print "waiting for GPS fix"
	gps_service = GpsService()
	current_pos = gps_service.getPosition()
	while not current_pos.valid:
		time.sleep(1)
		current_pos = gps_service.getPosition()
	LocalCoordinates
	while mpu_valid < 0:
		time.sleep(1.0)
		mpu_valid = mpu9150.mpuInit(1, 50, 4)
	print mpu_valid
	mpu9150.setMagCal('./magcal.txt')
	mpu9150.setAccCal('./accelcal.txt')
	for i in range(1000): # flushing a bit of sensor fifo to stabilize sensor
		time.sleep(1/CONTROL_RATE)
		mpu9150.mpuRead()
	robot.setSteeringAngle(0.0)
	robot.setSpeed(0)
	while True:
		#robot.resetWatchdog()
		target_pos= wp.getCurrentWayPoint()
		if target_pos == None: # done with the path
			break
		origin_pos = wp.getPreviousWaypoint()
		sensors = populateSensorMap(robot, gps_service)
		if sensor[IController.imu_key][0] < 0 : #invalid imu sample, wait a bit ot read next
			time.sleep(0.01)
			continue
		
		if new_gps_fix :
			state_estimate_service.computeEKF(sensor[IController.imu_key][1][2], sensor[IController.odometry_key], , , DT)
		else:
			state_estimate_service.computeEKF(sensor[IController.imu_key][2], sensor[IController.odometry_key], None, None, DT)
		
		# need to convert gps positions to XY positions
		if tracker_counter == TRACKER_RATE:
			path_curvature = path_tracker.computeSteering(EuclidianPoint(), EuclidianPoint(), robot.getXYPos(), robot.getEuler()[2])
			tracker_counter = 0
		else:
			tracker_counter = tracker_counter + 1					
		#compute command from path_curvature
		#steering can be extracted from curvature while speed must be computed from curvature and max_speed
		steering = sinh(WHEEL_BASE * path_curvature) 
		#command needs to be computed for speed using PID control or direct P control
		speed = speedFromSteering(steering))	
		
		robot.setSpeed(0.0)
		robot.setSteeringAngle(0.0)	
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
