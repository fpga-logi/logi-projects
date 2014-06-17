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
