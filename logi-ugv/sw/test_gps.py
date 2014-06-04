import logi
import time
from binascii import *
from string import *

# reset fifo
#logi.logiWrite(0x0010, (0x01, 0x01))
while True:
	time.sleep(0.1)
	frame = logi.logiRead(0x0080, 82)
	#gyro_tuple = logi.logiRead(0x0002, 2)
	#gyro_x = (gyro_tuple[1] << 8) | gyro_tuple[0]
	#if (gyro_tuple[1] & 0x80) != 0:
#		gyro_x = -32768 + (gyro_x & 0x7FFF)
#	print gyro_x
	
#	sonar = logi.logiRead(0x0041, 2)
#	sonar_tp = (sonar[1] << 8) | sonar[0]
#	sonar_cm = float(sonar_tp)/57.0
#	if sonar_cm > 4.0 :
#		print "sonar : "+str(sonar_cm)+" cm"
	frame_size = frame[0]
	#print frame
	#print frame_size
	#continue
	nmea_str = "".join(str(unichr(a)) for a in frame[2:frame_size+2])
	print nmea_str
	nmea_fields =  split(nmea_str, ',')
	if nmea_fields[6] > '0':
		lat = float(nmea_fields[2])/100
		long = float(nmea_fields[4])/100
		if nmea_fields[3] == "S":
			lat = -lat
		if nmea_fields[5] == "W":
                        long = -long 
		print "lat: "+str(lat)+", long: "+str(long)

nmea_fields =  split(nmea_str, ',')
print nmea_fields
#print float(nmea_fields[1])
exit()


while a[0] < 32:
	a = logi.logiRead(0x0010, 2)
	#print a
	time.sleep(0.1)

frame = logi.logiRead(0x0000, 32)
while a[0] < 32:
        a = logi.logiRead(0x0010, 2)
        #print a
        time.sleep(0.1)
frame = frame + logi.logiRead(0x0000, 32)

print len(frame)
sum = 0x00		 
nmea_str = "".join(str(unichr(a)) for a in frame)
nmea_fields =  split(nmea_str, ',')
print nmea_fields
print float(nmea_fields[1])
