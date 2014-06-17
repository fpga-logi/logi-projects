
from numpy  import *
from math import *
import math

CALIBRATE_TICK = 1.0
CALIBRATE_DISTANCE = 1.0 
CONV_FACTOR = CALIBRATE_DISTANCE/CALIBRATE_TICK


class RobotState():
	
	def __init__(self):
		#2D robot state, x position, y position, heading, speed
		self.x = array([0.0, 0.0, 0.0, 0.0])
		self.H = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])
		# process error, to be evaluated ? I believe no ...
		self.Q = array([[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.01, 0.0], [0.0, 0.0, 0.0, 0.01]])
		self.P = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])

		# need to estimate measurement error for GPS ...
		self.R = array([[0.4, 0.0, 0.0, 0.0], [0.0, 0.4, 0.0, 0.0], [0.0, 0.0, 0.1, 0.0], [0.0, 0.0, 0.0, 0.1]])
		# need to define Q, H

	def computeStateEvolution(self, x, F):
		x = dot(F, x)
		return x
		
	def computeMeasurementPrediction(self, H, x):
		zp = dot(H, x)		
		return 	zp

	def computeMeasurementPredictionError(self,z, zp):
		v = z - zp
		return v

	def computeStateCovariance(self,P, F, Q):
		#FPF'+ Q
		P = dot(dot(F, P), transpose(F)) + Q
		return P		
		
	def computeMeasurementPredictionCovariance(self, P, R, H):
		# S = HPH' + R
		S = dot(dot(H, P), transpose(H)) + R		
		return S		

	def computeFilterGain(self, S, H, P):
		# W = PHS^(-1)
		W = dot(dot(P, H), linalg.inv(S))
		return W		
	
	def computeUpdatedStateCovariance(self, W, P, S):
		#P = P - WSW'
		P = P - dot(dot(W, S), transpose(W))		
		return P	
	
	def computeUpdatedStateCovarianceExtended(self, W, P, H):
		#P = P - WHP'
		P = P - dot(dot(W, H), P)		
		return P		

	def computeUpdatedState(self, x, W, v):
		x = x + dot(W, v)	
		return x


	def kalmanLoop(self,measured_heading, measured_speed, measured_x, measured_y, dt):
		toRad = math.pi/180.0		

		# Prediction
		F = array([[1.0, 0, 0, math.sin(self.x[2]*toRad)*dt], \
			[0, 1.0, 0, math.cos(self.x[2]*toRad)*dt],\
			[0, 0, 1.0, 0], [0, 0, 0, 1.0]])

		F = array([[1.0, 0, 0, math.cos(self.x[2]*toRad)*dt], \
			[0, 1.0, 0, math.sin(self.x[2]*toRad)*dt],\
			[0, 0, 1.0, 0], [0, 0, 0, 1.0]])
		if measured_x == None:
			self.H[0][0] = 0.0
			measured_x = 0.0
		else:
			self.H[0][0] = 1.0
		if measured_y == None:
			self.H[1][1] = 0.0
			measured_y = 0.0
		else:
			self.H[1][1] = 1.0
		#print "F="+str(F)	
		self.x = self.computeStateEvolution(self.x, F)
		if self.x[2] > 180.0:
			self.x[2] = self.x[2] - 360.0
		#print "x+="+str(self.x)
		zp = self.computeMeasurementPrediction(self.x, self.H)
		#print "Z+="+str(zp)
		#if sensors == None:
		#	return self.x
		#Observation
		#heading_measure = sensors[IController.imu_key][2] # heading estimate should be third value of the eulerian attitude
		#odometry =  sensors[IController.odo]	
		#speed = odometry/(TICK_PER_TURN) * (2*math.pi*WHEEL_RADIUS)
		z = array([measured_x, measured_y, measured_heading, measured_speed])
		
		v = self.computeMeasurementPredictionError(z,zp)
		#print "V="+str(v)
		#Correction		
		self.P = self.computeStateCovariance(self.P, F, self.Q)
		#print "P+="+str(self.P)			
		S = self.computeMeasurementPredictionCovariance(self.P, self.R, self.H)
		#print "S="+str(S)
		W = self.computeFilterGain(S, self.H, self.P)
		#print "W="+str(W)
		#self.P = self.computeUpdatedStateCovariance(W, self.P, S)
		self.P = self.computeUpdatedStateCovarianceExtended(W, self.P, self.H)
		#print "P="+str(self.P)
		self.x = self.computeUpdatedState(self.x, W, v)	
		if self.x[2] > 180.0: # clamp heading to 180.0 to match measurement type
			self.x[2] = self.x[2] - 360.0
			
		# http://www.cs.cmu.edu/~motionplanning/papers/sbp_papers/integrated3/kleeman_kalman_basics.pdf
		
		# based on http://orbit.dtu.dk/fedora/objects/orbit:62052/datastreams/file_5388217/content
		# we consider a constant speed model, thus acceleration and angular velocity are the error of the system
		# it means that the measurement of the acceleration and angular speed (either by gyro, or differential on heading from IMU) 
		# are direclty the noise of the system ! It allows to have a constant Q


		#x(t+1) = Fx(t) + But
		#
		#	1 | 0 | 0 | sin(theta)*dt	
		#F = 	0 | 1 | 0 | cos(theta)*dt
		#	0 | 0 | 1 | 0
		#	0 | 0 | 0 | 1
		
		#
		#	(dt^2)/2
		#B =	(dt^2)/2
		#	dt
		#	dt
		
		# maybe we should ignore command ... 
		#	s'sin(theta')
		#	s'cos(theta')
		#ut = 	1
		#	1
		#	
		
		
		# Start of Observation part
		# measurement prediction, Zt = Hx (How to determine observation model ... Identity to start)
		# measurement residual computation => noise v = z - Zt (easy ...)
		# noise covariance computation Q = cov(v) (how to compute covariance) will be considered static (not best case)
		# Start of correction part		
		# State prediction covariance computation P = FPF'+ Q
		# Measurement prediction covariance S = HPH' + R
		# Filter gain computation W = PHS^(-1)
		# Updated state covariance P = P - WSW'
		
		# Following can be computed even if model was not updated	
		# Update state estimate x = x + Wv
		
		

		
	
		return self.x
	

if __name__ == "__main__":
	state = RobotState()
	toRad = math.pi/180.0
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
                mpu_valid = mpu9150.mpuInit(1, 50, 4)
        print mpu_valid
        mpu9150.setMagCal('./magcal.txt')
        mpu9150.setAccCal('./accelcal.txt')
	dt = 0.020
	var = 100.0
	heading = 0.0
	# init encoder
	logi.logiWrite(0x0003, (0x01, 0x01))
	logi.logiWrite(0x0003, (0x00, 0x00))
	while var > 1.0:	
		valid = mpu9150.mpuRead()
		if valid >= 0:
			euler =  mpu9150.getFusedEuler()
			var = heading - euler[3]
			heading = euler[3] 	
	state.x[0] = 0.0
	state.x[1] = 0.0
	state.x[2] = heading
	state.x[3] = 0.0
	old_enc = 0
	while True:
		
		valid = mpu9150.mpuRead()
		if valid >= 0:
			euler =  mpu9150.getFusedEuler()
		else:
			time.sleep(0.01)
			continue
		enc_reg = logi.logiRead(0x0003, 2)
		enc_val = (enc_reg[1] << 8) | enc_reg[0]
		
		if enc_val < old_enc:
			enc_val = enc_val + (65535-old_enc)		
		speed = (float(dist - old_dist)*CONV_FACTOR)/dt
		old_enc = enc_val 
		old_dist = dist
		state.kalmanLoop( euler[2], speed, None, None, dt)
		print state.x
		x_pos.append(state.x[0])
		y_pos.append(state.x[1])
		heading_filtered.append(state.x[2])
		speed_filtered.append(state.x[3])
		
	
