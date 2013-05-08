import mpu9150
import time

mpu9150.mpuInit(1, 10, 4)
mpu9150.setMagCal('magcal.txt')
mpu9150.setAccCal('accelcal.txt')
while True :
	i = mpu9150.mpuRead()
	if i >= 0:
		print mpu9150.getFusedEuler()
	time.sleep(0.1)

