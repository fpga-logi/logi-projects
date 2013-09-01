import logipi, time, random


#eye_ball = [0x3C, 0x7E, 0xFF, 0xFF, 0xFF, 0xFF, 0x7E, 0x3C]
eye_ball = [0x3C, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E, 0x7E]

eye_blink = [0x00, 0x00, 0x3C, 0x7E, 0x7E, 0x3C, 0x00, 0x00]

pupil_small = [0x03, 0x03]
large_pupil = [0x03, 0x0F, 0x0F, 0x03]


def countOneBits(bits):
	count = 0
	masked = 0x00
	for i in range(0, 8):
		masked = bits & (1 << i)
		if masked != 0 :
			count = count + 1
	return count

def getEyeBuffer(posx, posy, pupil=pupil_small):
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

def writeEye(eye_buffer):
        long_buffer = tuple()
	for k in range(0, 8):
        	#logipi.directWrite(0x0001, (eye_buffer[k],k+1, eye_buffer[k], k+1), 0)
		long_buffer = long_buffer +(eye_buffer[k],k+1, eye_buffer[k], k+1,)
	logipi.directWrite(0x0001, long_buffer[0:16], 0)
	time.sleep(0.001)
	logipi.directWrite(0x0001, long_buffer[16:32], 0)


logipi.directWrite(0x0000,(0xFF, 0x00), 0)

logipi.directWrite(0x0010,(0x04, 0x00), 0)
logipi.directWrite(0x0011,(0x00, 0x08), 0)
intens = 0 ;
while True:
	logipi.directWrite(0x0012,((intens & 0x00FF), intens >> 8), 0)
	logipi.directWrite(0x0013,((intens & 0x00FF), intens >> 8), 0)
	logipi.directWrite(0x0014,((intens & 0x00FF), intens >> 8), 0)
	time.sleep(0.001)
	intens = intens + 1 ;
	if intens > 0x0800:
		intens = 0


print logipi.directRead(0x0010,2, 0)
print logipi.directRead(0x0011,2, 0)
print logipi.directRead(0x0012,2, 0)
print logipi.directRead(0x0013,2, 0)
exit() 


logipi.directWrite(0x0001, (0x01,0x0C, 0x01, 0x0C), 0)
logipi.directWrite(0x0001, (0xF1,0x0A, 0xF1, 0x0A), 0)
logipi.directWrite(0x0001, (0x00,0x0F, 0x00, 0x0F), 0)
logipi.directWrite(0x0001, (0x00,0x09, 0x00, 0x09), 0)
logipi.directWrite(0x0001, (0x07,0x0B, 0x07, 0x0B), 0)


logipi.directWrite(0x0008, (0x80, 0x00));
logipi.directWrite(0x0009, (0x80, 0x00));
logipi.directWrite(0x000A, (0x80, 0x00));
logipi.directWrite(0x000B, (0x80, 0x00));

time.sleep(5);

logipi.directWrite(0x0008, (0x80, 0x00));
logipi.directWrite(0x0009, (0x80, 0x00)); 
logipi.directWrite(0x000A, (0xFF, 0x00));
logipi.directWrite(0x000B, (0x00, 0x00));


time.sleep(5);

logipi.directWrite(0x0008, (0x80, 0x00));
logipi.directWrite(0x0009, (0x80, 0x00));
logipi.directWrite(0x000A, (0x00, 0x00));
logipi.directWrite(0x000B, (0xFF, 0x00));

time.sleep(5);

logipi.directWrite(0x0008, (0x80, 0x00));
logipi.directWrite(0x0009, (0x80, 0x00));
logipi.directWrite(0x000A, (0x80, 0x00));
logipi.directWrite(0x000B, (0x80, 0x00));

for i in range(-3, 4):
	for j in range(-3,4):
		writeEye(getEyeBuffer(i, j))
		time.sleep(0.1)

writeEye(getEyeBuffer(0, 0))
writeEye(eye_blink)
time.sleep(0.1)
writeEye(getEyeBuffer(0, 0))
time.sleep(0.1)
writeEye(eye_blink)
time.sleep(0.1)
writeEye(getEyeBuffer(0, 0))



while True:
	
	sleepTime = random.randrange(3, 15)
	if sleepTime > 10 :
		logipi.directWrite(0x0008, (0xFF, 0x00));
		logipi.directWrite(0x0009, (0x00, 0x00));
		writeEye(getEyeBuffer(0, 0, large_pupil))
                time.sleep(1)
		writeEye(getEyeBuffer(0, 0))
		logipi.directWrite(0x0008, (0x80, 0x00));
		logipi.directWrite(0x0009, (0x80, 0x00));
	elif sleepTime > 5:
		writeEye(getEyeBuffer(1, -2))
		time.sleep(0.1)
		writeEye(getEyeBuffer(2, -2))
		time.sleep(0.1)
		logipi.directWrite(0x0008, (0xB0, 0x00));
                logipi.directWrite(0x0009, (0xB0, 0x00));
		writeEye(getEyeBuffer(3, -2))
		time.sleep(0.1)
		writeEye(getEyeBuffer(2, -2))
		time.sleep(0.1)
		writeEye(getEyeBuffer(1, -2))
		time.sleep(0.1)
		writeEye(getEyeBuffer(0, -2))
		time.sleep(0.1)
		writeEye(getEyeBuffer(-1, -2))
                time.sleep(0.1)
		writeEye(getEyeBuffer(-2, -2))
		logipi.directWrite(0x0008, (0x50, 0x00));
                logipi.directWrite(0x0009, (0x50, 0x00));
                time.sleep(0.1)
		writeEye(getEyeBuffer(-3, -2))
                time.sleep(0.1)
		writeEye(getEyeBuffer(-2, -2))
                time.sleep(0.1)
		writeEye(getEyeBuffer(-1, -2))
                time.sleep(0.1)
		writeEye(getEyeBuffer(0, 0))
		logipi.directWrite(0x0008, (0x80, 0x00));
                logipi.directWrite(0x0009, (0x80, 0x00));
	else:
		writeEye(getEyeBuffer(0, 0))
		logipi.directWrite(0x0008, (0xB0, 0x00));
                logipi.directWrite(0x0009, (0x50, 0x00));
		writeEye(eye_blink)
		time.sleep(0.1)
		writeEye(getEyeBuffer(0, 0))
		logipi.directWrite(0x0008, (0x80, 0x00));
                logipi.directWrite(0x0009, (0x80, 0x00));
		time.sleep(0.1)
		logipi.directWrite(0x0008, (0xB0, 0x00));
                logipi.directWrite(0x0009, (0x50, 0x00));
		writeEye(eye_blink)
		time.sleep(0.1)
		logipi.directWrite(0x0008, (0x80, 0x00));
                logipi.directWrite(0x0009, (0x80, 0x00));
		writeEye(getEyeBuffer(0, 0))
	time.sleep(sleepTime)
