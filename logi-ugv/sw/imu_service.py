import mpu9150


class ImuService():

	declination = 8.71 #boulder, 0.083 for Toulouse

	
	def __init__(self, update_rate)
		self.mpu_valid = -1.0		
		while mpu_valid < 0:
			time.sleep(0.5)
			self.mpu_valid = mpu9150.mpuInit(1, update_rate, 4)
		

	def setCalibrationFiles(self, mag, acc):
		mpu9150.setMagCal(mag)
		mpu9150.setAccCal(acc)
		
	def getAttitude(self):
		valid = mpu9150.mpuRead()
		if valid > 0:
			euler = robot.getEuler()
			#following compensate for magnetic declination, need to check if we need to substract or add declination value
			euler[2] = euler[2] - self.declination
			if euler[2] > 180.0:
				euler[2] = (euler[2] - 360.0)
 			elif euler[2] < -180.0:
				euler[2] = (euler[2] + 360.0)
		else:
			euler = (0.0, 0.0, 0.0)
		return (valid, euler, robot.getGyro()) 		
		
