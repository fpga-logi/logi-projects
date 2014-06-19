import mpu9150
import time
from math import *

mpu9150.mpuInit(1, 10, 4)
mpu9150.setMagCal('magcal.txt')
mpu9150.setAccCal('accelcal.txt')
while True :
	i = mpu9150.mpuRead()
	if i >= 0:
		#print mpu9150.getFusedEuler()
			
		mag = mpu9150.getCalMag()
		bearing = atan2(mag[0], mag[1])*(180.0/pi)
		if bearing < 0 :
			bearing = bearing +360
		print bearing
	time.sleep(0.1)

