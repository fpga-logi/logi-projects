from gps_service import Point


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
		self.waypoints.append( Point(40.575158, 75.755795))
		self.waypoints.append( Point(40.575176, 75.755768 ))
		self.waypoints.append( Point(40.575238, 75.755795 ))
		self.waypoints.append( Point(40.575221, 75.755901 ))  


	def getNextWayPoint(self):
		if self.currentWayPointIndex < len(self.waypoints):
       			self.currentWayPointIndex = self.currentWayPointIndex + 1
		else:
			raise WayPointException( "No more waypoints" )
		return self.waypoints[self.currentWayPointIndex]

	def getCurrentWayPoint(self):
		return self.waypoints[self.currentWayPointIndex]
	
	

		
	



