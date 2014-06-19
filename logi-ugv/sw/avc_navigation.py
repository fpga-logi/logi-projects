
import numpy

from path_tracking_service import PurePursuit as TrackingService
from state_estimate_service import RobotState
from ugv_platform import UgvPlatform as Robot
from coordinates import  *
from waypoint_provider import PlannerWayPointProvider 


from gps_service import GpsService
from speed_service import SpeedService

import math

#path of file containning the waypoints, we should adjust translation of  course over real gps coordinates. Otherwise it can cause the 
#car course to be shifted compared to the wanted one
PLANNER_WAYPOINT_FILE_PATH = "./avc_waypoints.txt"

CONTROL_RATE = 50 # rate at which the control is run
TRACKER_RATE = 5 # rate at which the path tracking algorithm is run
MAX_SPEED_MS = 10.0 # 10m/s is max speed (36km/h), this parameter must be adjusted depending on required agressivity
MIN_SPEED_MS = 3.5 # minimum speed base on what the encoder can measure and what speed the motor can generate
WHEEL_BASE = 0.30 # distance between front and rear axle, should be used for curvature to steering computation
DT = 1/CONTROL_RATE # period of control loop
DIST_TOLERANCE = 2.0 # distance at which the waypoint is assumed to be reached

# PID controller weights. will need to be changed if we move to hardware implementation
P = 30.0
I = 0.75
D = -2.0



#compute the speed based on current steering. This will need to be adjusted to avoid drifting
def speedFromSteeringAndDistance(steering):
	if distance == 0.0: # avoi division by zero
		distance = 0.01
	speed = (MAX_SPEED_MS * cos(steering)) - (1/math.pow(distance, 2) * MAX_SPEED_MS/10)# need to be adjusted ... 
	if speed < MIN_SPEED_MS:
		speed = MIN_SPEED_MS
	return speed
		

#ensure that the sensors are read only once. This avoid the communication with the FPGA to be everywhere in the code
def populateSensorMap(robot, gps_service, speed_service, imu_service):
	pos = robot.getPosition()
	sensor_map = {}
	sensor_map[Controller.imu_key] = imu_service.getAttitude()
	sensor_map[Controller.gps_key] = robot.getPosition()
	sensor_map[Controller.speed] = speed_service.getSpeed()
	return sensor_map
	
# navigation loop
#1) initialize all sensors/services and local coordinates system
#2) Wait for start button to be pressed
#3) Start of control loop
#	Read all sensors
#	Get current and previous waypoint
#	Transform everything to local coordinates system
#	Run the kalman filter, integrate gps in kalman filter if there is a new gps fix
#	Compute path tracking algorithm
#	Compute steering based on path tracking 
#	Compute distance to target, if lower than a given threshold, switch to next waypoint
#		If there is not next waypoint, end control loop
#	Compute speed based on steering and distance to target
#	Compute speed command using PID control
# 	Re-start loop

	

def nav_loop():
	robot = Robot()
	#initializing actuators and failsafe
	robot.setSteeringAngle(0.0)
	robot.setSpeed(0)
	robot.setSpeedFailsafe(0)
	robot.setSteeringFailsafe(0.0)

	#initializing state estimate service
	state = RobotState()
	# initializing path tracker
	path_tracker = TrackingService()
	#initializing waypoint provider
	wp = PlannerWayPointProvider(PLANNER_WAYPOINT_FILE_PATH) # use whatever WaypointProvider
	

	mpu_valid = -1
	print "waiting for GPS fix"
	gps_service = GpsService()
	current_pos = gps_service.getPosition()
	# wainting to get a valid GPS fix. Maybe should also wait to get a good fix before starting
	while not current_pos.valid:
		time.sleep(1)
		current_pos = gps_service.getPosition()
	#initializing local coordinates system to start on current spot
	coordinates_system = LocalCoordinates(current_pos)
	old_gps = current_pos
	
	#initiliaze mpu system
	imu_service = ImuService(CONTROL_RATE) # initialize imu at given rate, wait until the IMU is initialized
	#setting mpu calibration files (calibration should be re-run before every run)
	imu_service.setCalibrationFiles('./magcal.txt', 'acc_cal.txt')
	for i in range(1000): # flushing a bit of sensor fifo to stabilize sensor
		time.sleep(1/CONTROL_RATE)
		imu_service.getAttitude()
	
	# initalize speed service that reads encoders
	speed_service = SpeedService()
	
	#initialize PID variables
	target_speed = 0.0
	old_error = 0.0
	integral = 0.0
	
	while True:
		# need to read start button
		if not start_pressed :		
			time.sleep(0.2)
			continue
		#reseting watchdog at the beginning of loop
		robot.resetWatchdog()
		
		
		#waypoint service provide the current waypoint
		target_pos= wp.getCurrentWayPointXY()
		
	
		#no target point means path is done
		if target_pos == None: # done with the path
			break
		xy_target_pos = coordinates_system.convertGpstoEuclidian(target_pos)
		#get previous waypoint to draw the path between the two
		origin_pos = wp.getPreviousWaypoint()
		xy_origin_pos = coordinates_system.convertGpstoEuclidian(origin_pos)

		# populate the sensor structure to make sure we read all sensors only once per loop
		sensors = populateSensorMap(robot, gps_service, speed_service, imu_service)
		
		#imu has no valid sample, IMU helps keep the control loop rate as it delivers values at the right pace
		if sensor[IController.imu_key][0] < 0 : #invalid imu sample, wait a bit to read next
			time.sleep(0.01)
			continue
		
		#converting gps pos to the local coordinates system
		xy_pos = coordinates_system.convertGpstoEuclidian(sensors[Controller.gps_key])
		new_gps_fix = (sensors[Controller.gps_key].time != old_gps.time) and sensors[Controller.gps_key].valid and old_gps.valid
		old_gps = sensors[Controller.gps_key]
		
		# we have a new fix, integrate it to the kalman filter
		robot_heading = sensor[IController.imu_key][1][2]		
		if new_gps_fix :
			robot_state = state_estimate_service.computeEKF(robot_heading, sensor[IController.odometry_key], xy_pos.x, xy_pos.y, DT)
		else:
			robot_state = state_estimate_service.computeEKF(robot_heading, sensor[IController.odometry_key], None, None, DT)
		
		# updating xy_pos to estimated pos
		xy_pos = EuclidianPoint(robot_state[0], robot_state[1], xy_pos.time, True)
		robot_heading = robot_state[2]
		# execute tracker at a fraction at the control rate update
		if tracker_counter >= (CONTROL_RATE/TRACKER_RATE):
			path_curvature = path_tracker.computeSteering(xy_origin_pos, xy_target_pos, xy_pos, robot_heading)
			tracker_counter = 0
		else:
			tracker_counter = tracker_counter + 1	
		
		# if we reached target, move to the next
		distance_to_target = xy_pos.distanceTo(xy_target_pos)
		if distance_to_target < DIST_TOLERANCE:
			wp.getNextWayPoint()
			# for tracker to be executed on next iteration
			tracker_counter = (CONTROL_RATE/TRACKER_RATE)
				
		#steering can be extracted from curvature while speed must be computed from curvature and max_speed
		steering = math.sinh(path_curvature)*(math.pi/180.0)
		#command needs to be computed for speed using PID control or direct P control
		target_speed = speedFromSteeringAndDistance(steering, distance_to_target)	

		
		# doing the PID math, PID term needs to be adjusted
		error = (target_speed - sensor[IController.odometry_key])
        	derivative = error - old_error
        	old_error = error
        	cmd = error * P + derivative * D + integral * I
        	integral = integral + error
		if cmd < 0.0 :
                	cmd = 0
        	if cmd > 127.0:
                	cmd = 127
		# end of PID math
		robot.setSpeed(cmd)
		
		robot.setSteeringAngle(steering)
					
	
	# if ever we quit the loop, we need to set the speed to 0 and steering to 0
	robot.setSteeringAngle(0.0)        
	robot.setSpeed(0)
	print "Shutdown ESC then quit programm (for safety reason)"
        while True:
		time.sleep(1)	

if __name__ == "__main__":
	try:
		nav_loop()
	except KeyboardInterrupt:
		print "dying !"
		exit()
