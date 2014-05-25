import math
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

def importWaypoints(file_path):
	waypoints = []
	with open(file_path) as tsv:
    		for line in csv.reader(tsv, dialect="excel-tab"):
			if len(line) == 12:
				waypoints.append((line[8], line[9]))
	return waypoints

class Point(object):

	def __init__(self, lat, lon):
		self.lat = lat
		self.lon = lon
	
	def getLatDeg(self):
		return DmToD(self.lat)		

	def getLonDeg(self):
		return DmToD(self.lon)

class GpsTest(object):

	def __init__(self):
		self.equatorial_radius = 6378137   #WGS-84 equatorial radius
		self.equatorial_perimeter = (math.pi*2)*self.equatorial_radius
		self.lat_scale_factor = (self.equatorial_perimeter)/360.0 		

	def getPosition(self):
		return self.current_pos

	def setPosition(self, lat, lon):
		self.current_pos = Point(lat, lon)
	
	def setPositionDd(self, lat, lon):
		self.current_pos = Point(DToDm(lat), DToDm(lon))
	
	def setLatLonOrigin(self, lat, lon):
		self.origPoint = Point(lat, lon)
		toRad = (2*math.pi)/360.0
		lon_radius = math.sin((math.pi/2)-self.origPoint.getLatDeg()*toRad)* self.equatorial_radius
		lon_perimeter = (math.pi*2)*lon_radius
		self.lon_scale_factor = (lon_perimeter)/360.0

	def setLatLonOriginDd(self, lat, lon):
		self.origPoint = Point(DToDm(lat), DToDm(lon))
		toRad = math.pi/180.0
		lon_radius = math.sin((math.pi/2)-(lat*toRad))* self.equatorial_radius		
		lon_perimeter = (math.pi*2)*lon_radius
		self.lon_scale_factor = (lon_perimeter)/360.0	
	
	def getXYPos(self):
		pos = {}
		toRad = (2*math.pi)/360.0
		cp = self.getPosition()
		diffLat = cp.getLatDeg()-self.origPoint.getLatDeg()
		diffLon = cp.getLonDeg()-self.origPoint.getLonDeg()
		x = diffLon * self.lon_scale_factor   # sinus approximation, i still don't know why i get a 3times
		y = diffLat * self.lat_scale_factor  # sinus approximation
		dist = math.sqrt(pow(x, 2)+pow(y, 2))
		pos["x"] = x
		pos["y"] = y
		pos["dist"] = dist
		return pos



if __name__ == "__main__":
	
	myGps = GpsTest()

	corner_x_pos = []
	corner_y_pos =[]
	
	challenge_x_pos = []
	challenge_y_pos =[]
	
	wp = importWaypoints("./laas_waypoints.txt")
	
	
	#Starting line
	myGps.setLatLonOriginDd(float(wp[0][0]), float(wp[0][1]))
	for p in wp:
		myGps.setPositionDd(float(p[0]), float(p[1]))
		xy_pos = myGps.getXYPos()	
		corner_x_pos.append(xy_pos["x"])
		corner_y_pos.append(xy_pos["y"])
	
	plt.plot(corner_x_pos, corner_y_pos, 'k')
	plt.axis([-45, 45, -45, 45])
	plt.show()
	exit()
	#Dummy 1
	
	#myGps.setPositionDd(40.07111,-105.229899)
	#xy_pos = myGps.getXYPos()	
	#corner_x_pos.append(xy_pos["x"])
	#corner_y_pos.append(xy_pos["y"])

	#Dummy 2
	#myGps.setPositionDd(40.07111,-105.229293)
	#xy_pos = myGps.getXYPos()	
	#corner_x_pos.append(xy_pos["x"])
	#corner_y_pos.append(xy_pos["y"])

	
		

	#Corner 1	
	myGps.setPositionDd(40.071258964017034, -105.23002602159977)
	xy_pos = myGps.getXYPos()	
	corner_x_pos.append(xy_pos["x"])
	corner_y_pos.append(xy_pos["y"])	
	
	#barrel 1
	myGps.setPositionDd(40.071039022877812, -105.22996600717306)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])

	#barrel 2
	myGps.setPositionDd(40.070982025936246, -105.22995703853667)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])

	#barrel 3
	myGps.setPositionDd(40.070900972932577, -105.2299000415951)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])

	#barrel 4
	myGps.setPositionDd(40.070805000141263, -105.22986902855337)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])
	

	#Corner 2
	myGps.setPositionDd(40.07075596600771, -105.22971798665822)
	xy_pos = myGps.getXYPos()	
	corner_x_pos.append(xy_pos["x"])
	corner_y_pos.append(xy_pos["y"])	

	#hoop
	myGps.setPositionDd(40.070829978212714, -105.22953098639846)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])
	
	#Corner 3
	myGps.setPositionDd(40.070976996794343, -105.22919101640582)
	xy_pos = myGps.getXYPos()	
	corner_x_pos.append(xy_pos["x"])
	corner_y_pos.append(xy_pos["y"])	

	#Ramp
	myGps.setPositionDd(40.071081016212702, -105.22919897921383)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])
	
	
	#Corner 4
	myGps.setPositionDd(40.071331970393658, -105.22946602664888)
	xy_pos = myGps.getXYPos()	
	corner_x_pos.append(xy_pos["x"])
	corner_y_pos.append(xy_pos["y"])

	#Closing the path
	myGps.setPositionDd(40.071258964017034, -105.23002602159977)
	xy_pos = myGps.getXYPos()	
	corner_x_pos.append(xy_pos["x"])
	corner_y_pos.append(xy_pos["y"])


	#Finish line
	myGps.setPositionDd(40.071374969556928, -105.22978898137808)
	xy_pos = myGps.getXYPos()	
	challenge_x_pos.append(xy_pos["x"])
	challenge_y_pos.append(xy_pos["y"])


	plt.plot(corner_x_pos, corner_y_pos, 'k', challenge_x_pos, challenge_y_pos, 'o')
	plt.axis([-45, 45, -45, 45])
	plt.show()


	dist1 = math.sqrt(math.pow(corner_x_pos[0]-corner_x_pos[1], 2)+math.pow(corner_y_pos[0]-corner_y_pos[1], 2))
	dist2 = math.sqrt(math.pow(corner_x_pos[1]-corner_x_pos[2], 2)+math.pow(corner_y_pos[1]-corner_y_pos[2], 2))
	dist3 = math.sqrt(math.pow(corner_x_pos[2]-corner_x_pos[3], 2)+math.pow(corner_y_pos[2]-corner_y_pos[3], 2))
	

	print str(dist1)+", "+str(dist2)+", "+str(dist3)
	

