import math
import time
import threading
import csv
import logi
from string import *
from coordinates import *

#import mpu9150

def DmToD(Dm):
	D = int(Dm/100)
	m = (Dm - (D*100))	
	return D+(m/60)

def DToDm(D):
	Dm = int(D)
	m = (D-Dm)*60
	return (Dm*100)+m
	

GPS_ADDRESS = 0x080
class GpsService():
		

	def __init__(self):
		self.current_pos = GpsPoint(0.0, 0.0, 0.0, False) ; 	

	def getPosition(self):
		frame = logi.logiRead(0x080, 82)
                frame_size = frame[0]
                nmea_str = "".join(str(unichr(a)) for a in frame[2:frame_size+2])
		nmea_fields =  split(nmea_str, ',')
		if nmea_fields[6] > '0':
			lat = float(nmea_fields[2])
			long = float(nmea_fields[4])
			time = float(nmea_fields[1])
			if nmea_fields[3] == "S":
				lat = -lat
			if nmea_fields[5] == "W":
				long = -long
			self.current_pos = GpsPoint(DmToD(lat), DmToD(long), time, True)
			self.current_pos.setDilution(float(nmea_fields[8])*7.0)
			
		return self.current_pos


class SimulatedGpsService():
		
	def __init__(self):
		self.current_pos = GpsPoint(0.0, 0.0, 0.0, True) ; 	

	def getPosition(self):
		return self.current_pos


if __name__ == "__main__":
	nmea_file = open('nmea.log', 'w')
	xy_file = open('xy.log', 'w')
	service = GpsService()
	init_pos = service.getPosition()
	coord = LocalCoordinates(init_pos)
	mpu_valid = -1 
	#while mpu_valid < 0:
        #        time.sleep(1.0)
        #        mpu_valid = mpu9150.mpuInit(1, 10, 4)
        #print mpu_valid
        #mpu9150.setMagCal('./magcal.txt')
        #mpu9150.setAccCal('./accelcal.txt')
	
	while True:
		time.sleep(0.1)
		curr_pos = service.getPosition()
		nmea_str = str(curr_pos.lat)+", "+str(curr_pos.lon)+", "+str(curr_pos.dil)+"\n"
		xypos = coord.convertGpstoEuclidian(curr_pos)
		xy_str = str(xypos.x)+", "+str(xypos.y)+"\n"
		xy_file.write(xy_str)
		nmea_file.write(nmea_str)
#		print nmea_str
		#print mpu9150.getFusedEuler()
