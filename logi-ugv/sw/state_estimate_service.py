
from numpy  import *
from math import *



class RobotState():
	
	def __init__(self):
		#2D robot state, x position, y position, heading, speed
		self.x = array([0.0, 0.0, 0.0, 0.0])
		self.H = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])
		# process error, to be evaluated ? I believe not ...
		# some uncertainty is required on x and y for gps corrections to be taken into account
		self.Q = array([[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])
		self.P = array([[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]])

		# need to estimate measurement error for GPS ...
		self.R = array([[1.5, 0.0, 0.0, 0.0], [0.0, 1.5, 0.0, 0.0], [0.0, 0.0, 2.0, 0.0], [0.0, 0.0, 0.0, 1.0]])
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


	def computeEKF(self,measured_heading, measured_speed, measured_x, measured_y, dt):
		toRad = math.pi/180.0		

		# Prediction
		# compute state transition matrix for simple robot movement
		# movement is based on heading and speed only
		F = array([[1.0, 0, 0, math.sin(self.x[2]*toRad)*dt], \
			[0, 1.0, 0, math.cos(self.x[2]*toRad)*dt],\
			[0, 0, 1.0, 0], [0, 0, 0, 1.0]])

		# if position was measured, integrate the position as a correction for next steps
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
		
		# compute state evolution
		self.x = self.computeStateEvolution(self.x, F)

		#use heading as 2pi modulus not pi -pi range
		if self.x[2] > 360.0:
			self.x[2] = self.x[2] - 360.0
		if measured_heading < 0 :
			measured_heading = 360.0 + measured_heading	
		#print "x+="+str(self.x)

		# compute measurement prediction, H consider direct measurement of state features
		zp = self.computeMeasurementPrediction(self.x, self.H)
		#print "Z+="+str(zp)
	
		z = array([measured_x, measured_y, measured_heading, measured_speed])
		
		# compute measurement prediction error
		v = self.computeMeasurementPredictionError(z,zp)
		
		# clamp v for input based on heading and predicted heading, managing non-linearity on error for heading
		if v[2] > 180.0:
			v[2] = v[2] - 360.0
		if v[2] < -180.0:
			v[2] = v[2] + 360.0
	
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

		# still need to handle non contiguity on 360.0 to 0.0 ... should take minimum distance between the two instead of direct difference.
		if self.x[2] > 360.0: # clamp heading to 180.0 to match measurement type
			self.x[2] = self.x[2] - 360.0
			
		# http://www.cs.cmu.edu/~motionplanning/papers/sbp_papers/integrated3/kleeman_kalman_basics.pdf
		
		# based on http://orbit.dtu.dk/fedora/objects/orbit:62052/datastreams/file_5388217/content
		# we consider a constant speed model, thus acceleration and angular velocity are the error of the system
		# it means that the measurement of the acceleration and angular speed (either by gyro, or differential on heading from IMU) 
		# are direclty the noise of the system ! It allows to have a constant Q
	
		return self.x

		def getCurrentState(self):
			return self.x



def drawCircle(state, dt):
	angular_speed = 5.0
	state = state + angular_speed
	radius = 2.0
	if state > 360.0:
		state = 0.0
	toRad = math.pi/180.0 
	speed = (math.tan(angular_speed*toRad)*radius)/dt # constant speed
	heading = state + 90.0 
	x = math.cos(state*toRad)*radius
	y = math.sin(state*toRad)*radius
	if heading > 180.0:
		heading = heading - 360.0
	return (x, y, heading, speed, state)

def drawLine(state, dt):
	state = state + dt
	speed = 2.0
	heading = 16.0
	x = math.cos(heading*toRad)*state*speed
	y = math.sin(heading*toRad)*state*speed
	return (x, y, heading, speed, state)
	

if __name__ == "__main__":
	state = RobotState()
	toRad = math.pi/180.0
	heading = 0.0
	speed = 0.0
	dt = 0.020

	
	x_pos = []
	y_pos =[]
	x_pos_true = []
	y_pos_true =[]
	x_pos_noise = []
	y_pos_noise =[]
	state.x[0] = 0.0
	state.x[1] = 0.0
	state.x[2] = 0.0
	state.x[3] = 0.0
	
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
	state_mem = 0.0	
	for i in range(5000):
		true_x, true_y, heading, speed, state_mem  = drawCircle(state_mem , dt)
		noised_heading = random.normal(loc=heading, scale=1.0)
		noised_speed = abs(random.normal(loc=speed, scale=0.1))
		#print "heading :"+str(noised_heading)+", speed :"+str(speed)
		#true_x = true_x + math.sin(heading*toRad)*0.1*speed
		#true_y = true_y +  math.cos(heading*toRad)*0.1*speed
		x_pos_true.append(true_x)
		y_pos_true.append(true_y)
		
		noisy_x = random.normal(loc=true_x, scale=1.5) + math.cos(noised_heading*toRad)*dt*noised_speed
		noisy_y = random.normal(loc=true_y, scale=1.5) +  math.sin(noised_heading*toRad)*dt*noised_speed
		#print str(noisy_x)+", "+str(noisy_y)

		x_pos_noise.append(noisy_x)
		y_pos_noise.append(noisy_y)
		heading_noised.append(noised_heading)
		speed_noised.append(noised_speed)
		
		if i % 5 == 0:
			state.kalmanLoop( noised_heading, noised_speed, random.normal(loc=true_x, scale=1.5), random.normal(loc=true_y, scale=1.5), dt)
		else:	
			state.kalmanLoop( noised_heading, noised_speed, None, None, dt)
		x_pos.append(state.x[0])
		y_pos.append(state.x[1])
		heading_filtered.append(state.x[2])
		speed_filtered.append(state.x[3])
		print "etimated speed : "+str(state.x[3])+", true speed : "+str(speed)
		print "etimated heading : "+str(state.x[2])+", true heading : "+str(heading)
		
	plt.subplot(211)
	plt.plot(x_pos, y_pos, 'r',x_pos_true,y_pos_true, 'b')
	#plt.plot(x_pos_true, y_pos_true)
	#plt.plot(x_pos_noise, y_pos_noise, '+')

	plt.subplot(212)
	plt.plot(heading_noised, speed_noised, '+b', heading_filtered, speed_filtered, '-r')

	plt.show()
	
