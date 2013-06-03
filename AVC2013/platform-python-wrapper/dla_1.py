import fcntl, os, time, struct, binascii, math
import mark1Rpi, mpu9150

from geopy import distance
from geopy.point import Point

import gps
from math import radians, cos, sin, asin, sqrt


MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

class AvcPlatform(object):
        waypoints = []
        waypoints.append( Point("40.575158 N; 75.755795 W"))
        waypoints.append( Point("40.575176 N; 75.755768 W"))
        waypoints.append( Point("40.575238 N; 75.755795 W"))
        waypoints.append( Point("40.575221 N; 75.755901 W"))  
	blob_fifo_id = 0
	blob_fifo_base_address = 0x0000
	classifier_lut_base_address = 0x1000
	servo_base_address = [0x2000, 0x2001]
	enc_base_address = [0x2002, 0x2004]
	leds_base_address = 0x2002

        session=gps.gps("localhost",2947)
        session.stream(gps.WATCH_ENABLE | gps.WATCH_NEWSTYLE)

	
	def __init__(self):
		mark1Rpi.fifoOpen(0)
	
	def initImu(self, acc_cal_file, mag_cal_file):
		mpu9150.mpuInit(1, 10, 4)
		mpu9150.setMagCal(mag_cal_file)
		mpu9150.setAccCal(acc_cal_file)
	
	def setServoPulse(self, index, pos):	
		mark1Rpi.directWrite(self.servo_base_address[index], (pos,0));
	
	def setLeds(self, val):
		mark1Rpi.directWrite(self.leds_base_address, (val,0));
	
	def setServoAngle(self, index, angle):
		quanta = 255.0/(MAX_ANGLE-MIN_ANGLE)
		pulse = 127.0 + (quanta * angle)
		self.setServoPulse(index, int(round(pulse)))

	def getEncoderValue(self, index):
		count_tuple = mark1Rpi.directRead(self.enc_base_address[index], 4);
		return ((count_tuple[3] << 24) + (count_tuple[2] << 16) + (count_tuple[1] << 8) + count_tuple[0])

	def getPlatformAttitude(self):
		i = mpu9150.mpuRead()
		return (i, mpu9150.getFusedEuler(), mpu9150.getRawGyro())

	def setColorLut(self, lut_file):
		f = open(lut_file, "rb")
		values_tuple = ()
		tuple_size = 0
		try:
			byte = f.read(1)
			while byte != "":
				values_tuple = values_tuple + byte
				values_tuple = values_tuple + 0x00
				tuple_size = tuple_size + 2
				byte = f.read(1)
			mark1Rpi.directWrite(self.classifier_lut_base_address, values_tuple, tuple_size);
		finally:
			f.close()

	def getBlobPos(self):
		blob_data = fifoRead(0, 32*3*2) # 32 blobs of 6 octet
		blobs_tuple = ()
		for i in range(len(blob_data)):
			blob_info = ()
			blob_info = blob_info + (((blob_data(i) & 0x03) << 8)+blob_data(i+1)) # posx0
			blob_info = blob_info + (((blob_data(i+2) & 0x0F) << 6)+((0x3F & blob_data(i+1))>>2)) # posy0
			blob_info = blob_info + (((blob_data(i+3) & 0x2F) << 4)+((0xF0 & blob_data(i+2))>>4)) # posx1
			blob_info = blob_info + ((blob_data(i+4) << 2)+((0xC0 & blob_data(i+3))>>6)) # posy1
			blob_info = blob_info + blob_data(i+5) # blob class
			blobs_tuple = blobs_tuple + blob_info
		return blobs_tuple

        def computedist(self, p1,p2):
                lat1,lon1,alt1=Point(p1)
                lat2,lon2,alt2=Point(p2)
                lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
                # haversine formula
                dlon = lon2 - lon1
                dlat = lat2 - lat1
                a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
                c = 2 * asin(sqrt(a))
                km = 6367 * c
                return km


        def computebearin(self, p1,p2):
                lat1,lon1,alt1=Point(p1)
                lat2,lon2,alt2=Point(p2)
                lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
                # haversine formula
                dlon = lon2 - lon1
                dlat = lat2 - lat1
                y = sin(dlon) * cos(lat2) 
                x = cos(lat1) * sin(lat2) \
                    - sin(lat1) * cos(lat2) * cos(dlon)
                return atan2(y , x)
                    
 


if __name__ == "__main__":
	robot = AvcPlatform()
	robot.setLeds(0x55)
	time.sleep(2)
	robot.setLeds(0xAA)
	print robot.getEncoderValue(0)
	print robot.getEncoderValue(1)
	i = 0
        if True:
                p= Point("40.574996 N; 75.756124 W")
                lat,lon,altitude=p
                print "lat is", lat
                print robot.waypoints[0]
                print  distance.distance(robot.waypoints[0],robot.waypoints[1]).meters
                pos = robot.waypoints[0]
                report=robot.session.next()
                print report
                distance.distance=distance.VincentyDistance
                if report['class'] == 'TPV':
                        if hasattr(report, 'lat'):
                                #print "POS =",report.lat
                                cpos=Point(report.lat,report.lon)
                                chead=Point(report.track)
                                print "CPOS =", cpos
                                print "cheading=", chead
                print "dist to start line= " ,  distance.distance(robot.waypoints[0],pos).feet
                print "dist to p1= " ,  distance.distance(robot.waypoints[1],pos).feet
                #print "heading  to p1= " ,  distance.distance(robot.waypoints[1],pos).forward_azimuth
                #print distance.__dict__.keys()
                print "init servos"
                robot.setServoPulse(0,160) #home both servos
                robot.setServoPulse(1,127)
                time.sleep(15.5)
                print "3"
                time.sleep(.75)
                print "2"
                time.sleep(.75)
                print "1"
                print "go !!"
                speed1=165
                robot.setServoPulse(0,160) #steering fww 
                robot.setServoPulse(1,190) #speed FWD
                time.sleep(0.5)
                robot.setServoPulse(0,160)  #steering fwd
                robot.setServoPulse(1,speed1) # speed FWD
                time.sleep(2.5)
                robot.setServoPulse(0,190) #steering fww 
                robot.setServoPulse(1,speed1) #speed FWD
                time.sleep(2.75)
                robot.setServoPulse(0,160)  #steering fwd
                robot.setServoPulse(1,speed1) # speed FWD
                time.sleep(1.0)

                robot.setServoPulse(0,127) #home both servos
                robot.setServoPulse(1,127)
                time.sleep(1.5)
                print "Stop"

