import os
from gps import *
from time import *
import time
import threading

gpsd = None #seting the global variable
 
os.system('clear') #clear the terminal (optional)

class Point(object):
	def __init__(self, lat, lon):
		self.lat = lat
		self.lon = lon

class GpsService(threading.Thread):
	def __init__(self):
		threading.Thread.__init__(self)
		global gpsd #bring it in scope
		gpsd = gps(mode=WATCH_ENABLE) #starting the stream of info
		self.current_value = None
		self.daemon = True
		self.running = True #setting the thread running to true

	def run(self):
		global gpsd
		while True:
			gpsd.next()
			sleep(0.1)

	def getPosition(self):
		current_pos = Point(gpsd.fix.latitude, gpsd.fix.longitude)
		return current_pos

	
