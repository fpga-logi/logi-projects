
import logipi, time, random, math, threading





# each attitude is organized as : eyex, eyey, eye_type, eyebrow_right_angle, eyebrow_left_angle, mouth_right_angle, mouth_left_angle


eye_ball = [0x3C, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E]

eye_blink = [0x00, 0x00, 0x3C, 0x7E, 0x7E, 0x3C, 0x00, 0x00]

pupil_small = [0x03, 0x03]
large_pupil = [0x03, 0x0F, 0x0F, 0x03]

MIN_ANGLE = -45.0
MAX_ANGLE = 45.0
PULSE_CENTER = 127

def countOneBits(bits):
		count = 0
		masked = 0x00
		for i in range(0, 8):
			masked = bits & (1 << i)
			if masked != 0 :
				count = count + 1
		return count

def blinkLeds(logi, period, nb, power):
	for i  in range(nb):
		logi.setAllPwm(int(round(logi.pwmPeriod*power)))
		time.sleep(period/2)
		logi.setAllPwm(0)
		time.sleep(period/2)
	return

def fadeLeds(logi, period, nb, power):
	intens = 0
	for i  in range(nb):
		int(round(math.fabs(math.sin(intens)*0x0800)))
		intens = intens + 0.01
		logi.setAllPwm(int(round(logi.pwmPeriod*math.fabs(math.sin(intens)) )))
		time.sleep(period)
	logi.setAllPwm(0)
	return

def cycleLeds(logi, period, nb, power):
	for i in range(nb):
		logi.setPwm(i%3, int(round(logi.pwmPeriod*power)))
		logi.setPwm((i+1)%3, 0)
		logi.setPwm((i+2)%3, 0)
		time.sleep(period)
	logi.setAllPwm(0)
	return


class LogiFace(object):

	attitude = {	':|' : [0, 0, 0, 0.0, 0.0, 0.0, 0.0],
		':)' : [0, 0, 0, 0.0, 0.0, 30.0, -30.0, blinkLeds, 0.1, 100, 0.1], 
		':(' : [0, 0, 0, 0.0, 0.0, -30.0, 30.0, fadeLeds, 0.1, 100, 0.1], 
		'8$' : [0, 0, 1, 30.0, -30.0, 30.0, 30.0, cycleLeds, 0.1, 100, 0.1]}

	servo_base_address = [0x0008, 0x0009, 0x000A, 0x000B]
	mat_base_address = 0x0001
	pwm_base_address = 0x0010
	reg_base_address = 0x0000
	
	def getEyeBuffer(self, posx, posy, pupil=pupil_small):
		pupil_buffer = tuple()
		dimy = len(pupil)
		fp = 4 - (dimy/2) + posy
		lp = 4 + (dimy/2) + posy
		for i in range(0, 8):
			if i >= fp and i < lp:
				dimx = countOneBits(pupil[i-fp])
				decx = 4 - (dimx/2) + posx
				pupil_buffer = pupil_buffer + (eye_ball[i] & (~(pupil[i-fp] << (decx) )), ) 
			else:
				pupil_buffer = pupil_buffer + (eye_ball[i], ) 
		return pupil_buffer

	def initEye(self):
		logipi.directWrite(self.mat_base_address, (0x01,0x0C, 0x01, 0x0C), 0)
		logipi.directWrite(self.mat_base_address, (0xF1,0x0A, 0xF1, 0x0A), 0)
		logipi.directWrite(self.mat_base_address, (0x00,0x0F, 0x00, 0x0F), 0)
		logipi.directWrite(self.mat_base_address, (0x00,0x09, 0x00, 0x09), 0)
		logipi.directWrite(self.mat_base_address, (0x07,0x0B, 0x07, 0x0B), 0)

	def writeEye(self, eye_buffer):
		long_buffer = tuple()
		for k in range(0, 8):
			#logipi.directWrite(0x0001, (eye_buffer[k],k+1, eye_buffer[k], k+1), 0)
			long_buffer = long_buffer +(eye_buffer[k],k+1, eye_buffer[k], k+1,)
		logipi.directWrite(self.mat_base_address, long_buffer[0:16], 0)
		#time.sleep(0.001)
		logipi.directWrite(self.mat_base_address, long_buffer[16:32], 0)
	
	def setServoAngle(self, index, angle):
		quanta = 255.0/(MAX_ANGLE-MIN_ANGLE)
		pulse = 127.0 + (quanta * angle)
		self.setServoPulse(index, int(round(pulse)))
		
	def setServoPulse(self, index, pos):
		logipi.directWrite(self.servo_base_address[index], (pos,0));
	
	def setPwmDivider(self, div):
		logipi.directWrite(self.pwm_base_address, ((div & 0x00FF), div >> 8));
	def setPwmPeriod(self, period):
		self.pwmPeriod = period ;
		logipi.directWrite(self.pwm_base_address+1, ((period & 0x00FF), period >> 8));	
	def setPwm(self, index, val):
		logipi.directWrite(self.pwm_base_address+(2+index), ((val & 0x00FF), val >> 8));

	def setAllPwm(self, val):
		logipi.directWrite(self.pwm_base_address+2, ((val & 0x00FF), val >> 8, (val & 0x00FF), val >> 8, (val & 0x00FF), val >> 8));
		
	def writeReg(self, val):
		logipi.directWrite(self.reg_base_address, ((val & 0x00FF), val >> 8));

	def readReg(self):
		val_tuple = logipi.directRead(self.reg_base_address, 2);
		val = val_tuple[0]+(val_tuple[1] << 8)
		return val

	def writeAttitude(self, smiley):
		att = self.attitude[smiley]
		if att[2] == 0:
			self.writeEye(self.getEyeBuffer(att[0], att[1]))
		else:
			self.writeEye(self.getEyeBuffer(att[0], att[1], large_pupil))
		self.setServoAngle(0, att[3])
		self.setServoAngle(1, att[4])
		self.setServoAngle(2, att[5])
		self.setServoAngle(3, att[6])
		if len(att) > 10:
			att[7](self, att[8], att[9], att[10])


if __name__ == "__main__":
	face = LogiFace()
	face.initEye()
	face.setPwmDivider(4)
	face.setPwmPeriod(0x0800)
	face.writeAttitude(':)')
	face.writeAttitude(':(')
	face.writeAttitude('8$')
	cycleLeds(face, 0.1, 50, 0.01)
	intens = 0 
	inc = 1
	while True:
		face.setPwm(0, int(round(math.fabs(math.sin(intens)*0x0800))))
		face.setPwm(1, int(round(math.fabs(math.sin(intens)*0x0800))))
		face.setPwm(2, int(round(math.fabs(math.sin(intens)*0x0800))))
		time.sleep(0.01)
		intens = intens + 0.01
	





