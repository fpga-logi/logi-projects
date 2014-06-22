
import csv
from coordinates import *


## Waypoint must be provided in degree decimal not degree minute
class WayPointException(Exception):

	def __init__(self, value):
		self.value = value
	def __str__(self):
		return repr(self.value)

class AbstractWayPointProvider(object):
	
	def __init__(self):
		self.currentWayPointIndex = 0
		self.waypoints = []
	
	def getNextWayPoint(self):
       		raise NotImplementedError( "Should have implemented this" )
	def getCurrentWayPoint(self):
       		raise NotImplementedError( "Should have implemented this" )
	def getNbWaypoint(self):
       		raise len(self.waypoints)


class StaticWayPointProvider(AbstractWayPointProvider):

	def __init__(self):
		super(StaticWayPointProvider, self).__init__()
		self.waypoints.append( GpsPoint(40.575158, 75.755795))
		self.waypoints.append( GpsPoint(40.575176, 75.755768 ))
		self.waypoints.append( GpsPoint(40.575238, 75.755795 ))
		self.waypoints.append( GpsPoint(40.575221, 75.755901 ))  


	def getNextWayPoint(self):
		if self.currentWayPointIndex < len(self.waypoints):
       			self.currentWayPointIndex = self.currentWayPointIndex + 1
		else:
			raise WayPointException( "No more waypoints" )
		return self.waypoints[self.currentWayPointIndex]

	def getCurrentWayPoint(self):
		return self.waypoints[self.currentWayPointIndex]
	
	

class PlannerWayPointProvider(AbstractWayPointProvider):

	def __init__(self, wp_file):
		AbstractWayPointProvider.__init__(self)
		self.xy_waypoints = []
		i = 0
		with open(wp_file) as tsv:
			for line in csv.reader(tsv, dialect="excel-tab"):
				if len(line) == 12:
					if i == 0:
						xy_coord = LocalCoordinates(GpsPoint(float(line[8]), float(line[9]) ))
						self.xy_waypoints.append(xy_coord.convertGpstoEuclidian(GpsPoint(float(line[8]), float(line[9]) )))
					else:
						self.xy_waypoints.append(xy_coord.convertGpstoEuclidian(GpsPoint(float(line[8]), float(line[9]) )))
					self.waypoints.append( GpsPoint(float(line[8]), float(line[9]) ))
					print "wp["+str(i)+"] = "+line[8]+", "+line[9]                               
					i = i + 1

		self.currentWayPointIndex = 1

	
	
	def getNextWayPoint(self):
		if self.currentWayPointIndex < (len(self.waypoints)-1):
       			self.currentWayPointIndex = self.currentWayPointIndex + 1
		else:
			return None
		return self.waypoints[self.currentWayPointIndex]

	def getCurrentWayPoint(self):
		return self.waypoints[self.currentWayPointIndex]
	
	def getPreviousWayPoint(self):
                if self.currentWayPointIndex != 0:
                        return self.waypoints[self.currentWayPointIndex-1]
                else:
                        return None

	def getNextWayPointXY(self):
                if self.currentWayPointIndex < (len(self.waypoints)-1):
                        self.currentWayPointIndex = self.currentWayPointIndex + 1
                else:
                        return None
                return self.xy_waypoints[self.currentWayPointIndex]

        def getCurrentWayPointXY(self):
                return self.xy_waypoints[self.currentWayPointIndex]


	def getPreviousWayPointXY(self):
		if self.currentWayPointIndex != 0:
			return self.xy_waypoints[self.currentWayPointIndex-1]
		else:
			return None

		
	





