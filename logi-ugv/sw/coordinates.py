import math

class GpsPoint(object):
	def __init__(self, lat, lon, time = 0.0, valid = False):
		self.lat = lat
		self.lon = lon	
		self.valid = valid
		self.time = time
		self.dil = 100.0
	def setDilution(self, dil):
		self.dil = dil

class EuclidianPoint(object):
	def __init__(self, x, y, time = 0.0, valid = False):
		self.x = x
		self.y = y	
		self.time = time
		self.dil = 100.0
	
	def setDilution(self, dil):
		self.dil = dil
		

	def distanceTo(self, point):
		squared_dist = math.pow(point.x - self.x, 2) + math.pow(point.y - self.y, 2)
		return math.sqrt(squared_dist)



class LocalCoordinates():
	
	def __init__(self, orig):
		self.equatorial_radius = 6378137   #WGS-84 equatorial radius
		self.equatorial_perimeter = (math.pi*2)*self.equatorial_radius
		self.lat_scale_factor = (self.equatorial_perimeter)/360.0 	
		if orig != None:
			self.setOriginGpsPoint(orig)
	
	def getPosition(self):
		return self.current_pos

	def setLatLonOrigin(self, lat, lon):
		self.origPoint = GpsPoint(lat, lon)
		toRad = math.pi/180.0
		lon_radius = math.sin((math.pi/2)-(lat*toRad))* self.equatorial_radius		
		lon_perimeter = (math.pi*2)*lon_radius
		self.lon_scale_factor = (lon_perimeter)/360.0
	
	def setOriginGpsPoint(self, orig):
		self.origPoint = orig
		toRad = math.pi/180.0
		lon_radius = math.sin((math.pi/2)-(orig.lat*toRad))* self.equatorial_radius		
		lon_perimeter = (math.pi*2)*lon_radius
		self.lon_scale_factor = (lon_perimeter)/360.0	
	
	def convertGpstoEuclidian(self, cp):
		pos = {}
		toRad = (2*math.pi)/360.0
		diffLat = cp.lat - self.origPoint.lat
		diffLon = cp.lon - self.origPoint.lon
		x = diffLon * self.lon_scale_factor   
		y = diffLat * self.lat_scale_factor 
		eucPoint = EuclidianPoint(x, y, cp.time, cp.valid)
		eucPoint.setDilution(cp.dil) 
		return eucPoint

