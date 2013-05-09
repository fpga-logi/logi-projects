import fcntl, os, time, struct, binascii
import mark1Rpi, mpu9150

class avc_platform:

	blob_fifo_id = 0
	blob_fifo_base_address = 0x0000
	classifier_lut_base_address = 0x1000
	servo_base_address = {0x2000, 0x2001}
	enc_base_address = {0x2002, 0x2003}

	MIN_ANGLE = -45.0
	MAX_ANGLE = 45.0
	PULSE_CENTER = 127
	
	def __init__(self):
		mark1Rpi.fifoOpen(0)
	
	def initImu(self, acc_cal_file, mag_cal_file):
		mpu9150.mpuInit(1, 10, 4)
		mpu9150.setMagCal(mag_cal_file)
		mpu9150.setAccCal(acc_cal_file)
	
	def setServoPulse(self, index, pos):
		mark1Rpi.directWrite(servo_base_address(index), (0,pos), 2);
	
	def setServoAngle(self, index, angle):
		quanta = 255/(MAX_ANGLE-MIN_ANGLE)
		pulse = 127 + (quanta * angle)
		self.setServoPulse(index, pulse)

	def getEncoderValue(self, index):
		count_tuple = mark1Rpi.directRead(enc_base_address(index), 2);
		return (count_tuple(0) << 8 + count_tuple(1))

	def getPlatformAttitude(self):
		i = mpu9150.mpuRead()
		return (i, mpu9150.getFusedEuler(), mpu9150.getRawGyro())

	def setColorLut(self, lut_file)
		f = open(lut_file, "rb")
		values_tuple = ()
		tuple_size = 0
		try:
			byte = f.read(1)
			while byte != "":
				values_tuple = values_tuple + 0x00
				values_tuple = values_tuple + byte
				tuple_size = tuple_size + 2
				byte = f.read(1)
			mark1Rpi.directWrite(classifier_lut_base_address, values_tuple, tuple_size);
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

if __name__ == "__main__":
	
