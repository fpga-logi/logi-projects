import math
import time
import threading
import matplotlib.pyplot as plt
import csv

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
	def __init__(self, lat, lon):
		self.lat = lat
		self.lon = lon	

	
class GpsService(threading.Thread):
		

	def __init__(self):
		threading.Thread.__init__(self)
		self.equatorial_radius = 6378137   #WGS-84 equatorial radius
		self.equatorial_perimeter = (math.pi*2)*self.equatorial_radius
		self.lat_scale_factor = (self.equatorial_perimeter)/360.0 	
		self.current_value = None
		self.daemon = True
		self.running = True #setting the thread running to true

	def run(self):
		while self.running:
			#grapb gps data, set self.current_pos with coordinates translated to degree
			sleep(0.1)

	def stop(self):
		self.running = False

	def getPosition(self):
		return self.current_pos



