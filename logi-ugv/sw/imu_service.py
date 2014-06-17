import mpu9150


class ImuService():

	def __init__(self, update_rate)
		self.mpu_valid = -1.0		
		while mpu_valid < 0:
			time.sleep(0.5)
			self.mpu_valid = mpu9150.mpuInit(1, update_rate, 4)
		mpu9150.setMagCal('./magcal.txt')
		mpu9150.setAccCal('./accelcal.txt')

	def getAttitude(self):
		valid = mpu9150.mpuRead()
		return (valid, robot.getEuler(), robot.getGyro()) 		
		
