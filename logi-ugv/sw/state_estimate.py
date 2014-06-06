
from numpy  import *
from math import *
import math
import matplotlib.pyplot as plt



class RobotState():
	
	def __init__(self):
		#2D robot state, x position, y position, heading, speed
		self.x = array([0.0, 0.0, 15.0, 2.0])
		self.H = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])
		# process error, to be evaluated ? I believe no ...
		self.Q = array([[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]])
		self.P = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])

		# need to estimate measurement error for GPS ...
		self.R = array([[0.5, 0.0, 0.0, 0.0], [0.0, 0.5, 0.0, 0.0], [0.0, 0.0, 0.2, 0.0], [0.0, 0.0, 0.0, 0.2]])
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

	def predictState(self,measured_heading, measured_speed, measured_x, measured_y, dt):
		toRad = math.pi/180.0		

		# Prediction
		F = array([[1.0, 0, 0, math.sin(self.x[2]*toRad)*dt], [0, 1.0, 0, math.cos(self.x[2]*toRad)*dt], [0, 0, 1.0, 0], [0, 0, 0, 1.0]])
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
	heading = 16.0
	speed = 2.0
	x_pos = []
	y_pos =[]
	x_pos_true = []
	y_pos_true =[]
	x_pos_noise = []
	y_pos_noise =[]

	x_pos.append(state.x[0])
	y_pos.append(state.x[1])
	x_pos_true.append(state.x[0])
	y_pos_true.append(state.x[1])
	x_pos_noise.append(state.x[0])
	y_pos_noise.append(state.x[1])

	heading_noised = []
	speed_noised = []
	heading_noised.append(state.x[2])
	speed_noised.append(state.x[3])
	heading_filtered = []
	speed_filtered = []
	heading_filtered.append(state.x[2])
	speed_filtered.append(state.x[3])
	true_x = 0.0
	true_y = 0.0	
	noisy_x = 0.0
	noisy_y = 0.0	
	for i in range(20):
		noised_heading = random.normal(loc=1.0, scale=0.2)*heading
		noised_speed = random.normal(loc=1.0, scale=0.2)*speed
		true_x = true_x + math.sin(heading*toRad)*0.1*speed
		true_y = true_y +  math.cos(heading*toRad)*0.1*speed
		x_pos_true.append(true_x)
		y_pos_true.append(true_y)
		noisy_x = noisy_x + math.sin(noised_heading*toRad)*0.1*noised_speed
		noisy_y = noisy_y +  math.cos(noised_heading*toRad)*0.1*noised_speed
		x_pos_noise.append(noisy_x)
		y_pos_noise.append(noisy_y)
		heading_noised.append(noised_heading)
		speed_noised.append(noised_speed)
		if i % 2 == 0:
			state.predictState( noised_heading, noised_speed, noisy_x, noisy_y, 0.1)
		else:	
			state.predictState( noised_heading, noised_speed, None, None, 0.1)
		x_pos.append(state.x[0])
		y_pos.append(state.x[1])
		heading_filtered.append(state.x[2])
		speed_filtered.append(state.x[3])
		
	plt.subplot(211)
	plt.plot(x_pos, y_pos, '+k', x_pos_true, y_pos_true, x_pos_noise, y_pos_noise)

	plt.subplot(212)
	plt.plot(heading_noised, speed_noised, '+k', heading_filtered, speed_filtered)

	plt.show()
	
