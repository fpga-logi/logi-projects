import mpu9150
import time

class ImuService():

	declination = 8.71 #boulder, 0.083 for Toulouse

	
	def __init__(self, update_rate):
		self.mpu_valid = -1.0		
		while self.mpu_valid < 0:
			time.sleep(0.5)
			self.mpu_valid = mpu9150.mpuInit(1, update_rate, 4)
		

	def setCalibrationFiles(self, mag, acc):
		mpu9150.setMagCal(mag)
		mpu9150.setAccCal(acc)
		
	def getAttitude(self):
		valid = mpu9150.mpuRead()
		if valid >= 0:
			euler = mpu9150.getFusedEuler()
			#following compensate for magnetic declination, need to check if we need to substract or add declination value
			corrected_heading = euler[2] - self.declination
			if corrected_heading > 180.0:
				corrected_heading = (corrected_heading - 360.0)
 			elif corrected_heading < -180.0:
				corrected_heading = (corrected_heading + 360.0)
			euler = (euler[0], euler[1], corrected_heading)
			gyro = mpu9150.getRawGyro()
		else:
			euler = (0.0, 0.0, 0.0)
			gyro = (0.0, 0.0, 0.0)
		return (valid, euler, gyro) 		
		


if __name__ == "__main__":
	service = ImuService(50)
	service.setCalibrationFiles('./magcal.txt', './accelcal.txt')
	while True:
		att = service.getAttitude()
		if att[0] >= 0:
			print att
		time.sleep(0.020)
