import math
import time
import threading
import csv
import logi
from string import *
from controllers import LocalCoordinates

#import mpu9150

def DmToD(Dm):
	D = int(Dm/100)
	m = (Dm - (D*100))	
	return D+(m/60)

def DToDm(D):
	Dm = int(D)
	m = (D-Dm)*60
	return (Dm*100)+m

#point has lat lon encoded in degree not degree minute, gps coordinates must be converted
class Point(object):
	def __init__(self, lat, lon, valid = False):
		self.lat = lat
		self.lon = lon	
		self.valid = valid
		self.dil = 100.0
	def setDilution(self, dil):
		self.dil = dil
	
class GpsService():
		

	def __init__(self):
		self.current_pos = Point(0, 0, False) ; 	

	def getPosition(self):
		frame = logi.logiRead(0x080, 82)
                frame_size = frame[0]
                nmea_str = "".join(str(unichr(a)) for a in frame[2:frame_size+2])
                nmea_fields =  split(nmea_str, ',')
		if nmea_fields[6] > '0':
                       lat = float(nmea_fields[2])
                       long = float(nmea_fields[4])
                       if nmea_fields[3] == "S":
                              lat = -lat
                       if nmea_fields[5] == "W":
                              long = -long
                       self.current_pos = Point(DmToD(lat), DmToD(long), True)
		       self.current_pos.setDilution(float(nmea_fields[8])*7.0)
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
		xypos = coord.getXYPos(curr_pos)
		xy_str = str(xypos["x"])+", "+str(xypos["y"])+", "+str(xypos["dist"])+"\n"
		xy_file.write(xy_str)
		nmea_file.write(nmea_str)
#		print nmea_str
		#print mpu9150.getFusedEuler()
