
from numpy  import *
from math import *
import math
from state_estimate_service import *
from gps_service import *
from speed_service import *
from imu_service import *

if __name__ == "__main__":
	x_pos = []
	y_pos = []
	f = open('xy.log', 'w')
	heading_filtered = []
	speed_filtered = []
	state_service = RobotState()
        print "waiting for GPS fix"
        gps_service = GpsService()
        current_pos = gps_service.getPosition()
        while not current_pos.valid:
                time.sleep(1)
                current_pos = gps_service.getPosition()
                print current_pos.valid
       
        imu_service = ImuService(50)
	speed_service = SpeedService()
        imu_service.setCalibrationFiles('./magcal.txt', './accelcal.txt')
	dt = 0.020
	var = 100.0
	heading = 0.0
	while var > 1.0:	
		attitude = imu_service.getAttitude()
		print attitude
		if attitude[0] >= 0:
			var = heading - attitude[1][2]
			heading = attitude[1][2]
		time.sleep(0.020) 	
	print "Sytem calibrated and ready to go !"
	state_service.x[0] = 0.0
	state_service.x[1] = 0.0
	state_service.x[2] = heading
	state_service.x[3] = 0.0
	old_enc = 0
	while True:
		csv_line =  str(state_service.x[0])+", "+str(state_service.x[1])+"\n"
		f.write(csv_line)
		attitude = imu_service.getAttitude()
		if attitude[0] >= 0:
			euler =  attitude[1]
		else:
			time.sleep(0.01)
			continue
		speed = speed_service.getSpeed()
		state_service.computeEKF( euler[2], speed, None, None, dt)
		#print state_service.x
		x_pos.append(state_service.x[0])
		y_pos.append(state_service.x[1])
		heading_filtered.append(state_service.x[2])
		speed_filtered.append(state_service.x[3])
		
	
