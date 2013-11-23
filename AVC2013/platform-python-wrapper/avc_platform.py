import fcntl, os, time, struct, binascii, math
import mark1Rpi, mpu9150

MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

class ColorBlob:
	
	def __init__(self, x0, y0, x1, y1, blob_class):
		self.x = x0
		self.y = y0
		self.width = x1-x0
		self.height = y1-y0
		self.blob_class = blob_class
		self.cogx = self.x + self.width/2
		self.cogy = self.y + self.height/2


class AvcPlatform(object):

	blob_fifo_id = 0
	blob_fifo_base_address = 0x0000
	classifier_lut_base_address = 0x1000
	servo_base_address = [0x2000, 0x2001]
	enc_base_address = [0x2002, 0x2004]
	encoder_control_address = 0x2003
	leds_base_address = 0x2002
	watchdog_address = 0x2008
	watchdog_status_address = 0x2006
	
	def __init__(self):
		mark1Rpi.fifoOpen(0)
		self.servo_failsafe = [0x00, 0x00]
	def initImu(self, acc_cal_file, mag_cal_file):
		mpu9150.mpuInit(1, 10, 4)
		mpu9150.setMagCal(mag_cal_file)
		mpu9150.setAccCal(acc_cal_file)
	
	def setServoPulse(self, index, pos):	
		mark1Rpi.directWrite(self.servo_base_address[index], (pos,self.servo_failsafe[index]));
	
	def setServoFailSafeAngle(self, index, angle):
		quanta = 255.0/(MAX_ANGLE-MIN_ANGLE)
                pulse = 127.0 + (quanta * angle)
                pulse = max(min(int(round(pulse)), 255), 0)
		self.servo_failsafe[index] = pulse

	def setLeds(self, val):
		mark1Rpi.directWrite(self.leds_base_address, (val,0));
	
	def setServoAngle(self, index, angle):
		quanta = 255.0/(MAX_ANGLE-MIN_ANGLE)
		pulse = 127.0 + (quanta * angle)
		pulse = max(min(int(round(pulse)), 255), 0)
		self.setServoPulse(index, int(round(pulse)))

	def getEncoderValue(self, index):
		count_tuple = mark1Rpi.directRead(self.enc_base_address[index], 4);
		return ((count_tuple[3] << 24) + (count_tuple[2] << 16) + (count_tuple[1] << 8) + count_tuple[0])

	def resetEncoders(self):
		control_val =  mark1Rpi.directRead(self.encoder_control_address, 2)
		control_val[0] = control_val[0] | 0x03 
		mark1Rpi.directWrite(self.encoder_control_address, control_val) # going high
		control_val[0] = control_val[0] & 0xFC 
		mark1Rpi.directWrite(self.encoder_control_address, control_val) # going low

	def enableEncoders(self):
		control_val =  mark1Rpi.directRead(self.encoder_control_address, 2)
		control_val[0] = control_val[0] | 0x0C 
		mark1Rpi.directWrite(self.encoder_control_address, control_val) # high enable bits

	def disableEncoders(self):
		control_val =  mark1Rpi.directRead(self.encoder_control_address, 2)
		control_val[0] = control_val[0] & 0xF3 
		mark1Rpi.directWrite(self.encoder_control_address, control_val) # low enable bits

	def resetWatchdog(self):
		mark1Rpi.directWrite(self.watchdog_address, (0x01, 0x00)) # going high

	def getWatchdogStatus(self):
		status = mark1Rpi.directRead(self.watchdog_status_address, 2)
		return (status[0] & 0x01)

	def setSpeed(self, speed):
		byte_speed = int(speed)
		mark1Rpi.directWrite(self.pid_address, ((byte_speed & 0x00FF),((byte_speed & 0xFF00) >> 8))) 

	def setP(self, p_coeff):
		byte_coef = int(p_coeff*256)
		mark1Rpi.directWrite(self.pcoef_address ((byte_coef & 0x00FF),((byte_coef & 0xFF00) >> 8))) 

	def setI(self, i_coeff):
		byte_coef = int(i_coeff*256)
		mark1Rpi.directWrite(self.icoeff_address, ((byte_coef & 0x00FF),((byte_coef & 0xFF00) >> 8))) 

	def setD(self, d_coeff):
		byte_coef = int(d_coeff*256)
		mark1Rpi.directWrite(self.dcoeff_address, ((byte_coef & 0x00FF),((byte_coef & 0xFF00) >> 8))) 

	def getPlatformAttitude(self):
		i = mpu9150.mpuRead()
		return (i, mpu9150.getFusedEuler(), mpu9150.getRawGyro()) 

	def setColorLut(self, lut_file):
		f = open(lut_file, "rb")
		values_tuple = ()
		try:
			byte = f.read(1)
			while byte != "":
				#print byte
				unpacked_val = struct.unpack('B',byte)
                                values_tuple = values_tuple + unpacked_val
				#values_tuple = values_tuple + unpacked_val
				byte = f.read(1)
			#print values_tuple
			print 'sending : ', str(len(values_tuple)), 'in the color lut'
			#print hex(values_tuple[0]),hex(values_tuple[1]),hex(values_tuple[2])
			mark1Rpi.directWrite(self.classifier_lut_base_address, values_tuple);
			print 'done !\n'
		finally:
			f.close()
	
	def printColorLut(self):
		values_tuple = mark1Rpi.directRead(self.classifier_lut_base_address, 1024);
		for val in values_tuple :
			print hex(val)

	def getBlobPos(self):
		mark1Rpi.fifoReset(0)
		blob_data = mark1Rpi.fifoRead(0, 32*3*2) # 32 blobs of 6 octet
		blobs_tuple = []
		for i in range(0, len(blob_data), 6):
			y0 = blob_data[i]+((blob_data[i+1] & 0x03) << 8)  # posy0
			x0 = ((blob_data[i+2] & 0x0F) << 6)+((0x3F & blob_data[i+1])>>2) # posx0
			y1 = ((blob_data[i+3] & 0x2F) << 4)+((0xF0 & blob_data[i+2])>>4) # posy1
			x1 = (blob_data[i+4] << 2)+((0xC0 & blob_data[i+3])>>6) # posx1
			blob_class = blob_data[i+5] # blob class
			new_blob = ColorBlob(x0, y0, x1, y1, blob_class)
			blobs_tuple.insert(i/6,new_blob)
		return blobs_tuple

if __name__ == "__main__":
	robot = AvcPlatform()
	robot.setLeds(0x55)
	time.sleep(2)
	robot.setLeds(0xAA)
	print robot.getEncoderValue(0)
	print robot.getEncoderValue(1)
	robot.setServoAngle(1, 0.0)
	robot.setServoAngle(0, 0.0)
	print 'Watchdog status :', robot.getWatchdogStatus()
	robot.resetWatchdog()
	print 'Watchdog status :', robot.getWatchdogStatus()
	robot.setColorLut('lut_file.lut')
	#print 'lut sent \n'
	#robot.printColorLut()
	i = 0
	while True:
		robot.resetWatchdog()
		robot.setServoAngle(0, math.sin(i)*0.45)
		robot.setServoAngle(1, math.sin(i)*0.45)
	#	mark1Rpi.fifoReset(0)
	#	blobs = robot.getBlobPos()
	#	print "x:", blobs[0].cogx,", y:", blobs[0].cogy
		time.sleep(0.01)
		i =  i + 0.1
		if i > math.pi :
			i = 0

