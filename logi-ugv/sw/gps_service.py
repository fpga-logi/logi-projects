import math
import time
import threading
import csv
import logi
from string import *

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
	
class GpsService():
		

	def __init__(self):
		self.current_pos = Point(0, 0, False) ; 	

	def getPosition(self):
		frame = logi.logiRead(0x080, 82)
                frame_size = frame[0]
                nmea_str = "".join(str(unichr(a)) for a in frame[2:frame_size+2])
                nmea_fields =  split(nmea_str, ',')
                if nmea_fields[2] == "A":
                       lat = float(nmea_fields[3])
                       long = float(nmea_fields[5])
                       if nmea_fields[4] == "S":
                              lat = -lat
                       if nmea_fields[6] == "W":
                              long = -long
                       self.current_pos = Point(DmToD(lat), DmToD(long), True)
		return self.current_pos



