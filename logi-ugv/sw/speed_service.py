import math
import logi
import time	

CALIB_NB_TICKS = 324.0
CALIB_DISTANCE = 1.0

DISTANCE_BETWEEN_TICKS = CALIB_DISTANCE/CALIB_NB_TICKS
ENCODER_PERIOD_ADDRESS = 0x000E
class SpeedService():
		

	def __init__(self):
		self.current_speed = 0.0 ; 	

	def getSpeed(self):
		enc_reg = logi.logiRead(ENCODER_PERIOD_ADDRESS, 2)
        	enc_val = (enc_reg[1] << 8) | enc_reg[0]
        	if enc_val == 32767: # cannot measure tick period smaller than 32767us
                	self.current_speed = 0.0
		elif enc_val == 0: # saturate to maximum known speed ... should never reach that
			self.current_speed = 15.0
		else:
        		self.current_speed = DISTANCE_BETWEEN_TICKS/(float(enc_val)/1000000.0)
		return self.current_speed


class SimulatedSpeedService():
		
	def __init__(self):
		self.current_speed = 0.0 ; 	

	def getSpeed(self):
		return self.current_speed



if __name__ == "__main__":
	speed_service = SpeedService()
	logi.logiWrite(0x0000, (0x01, 0x01)) # enable watchdog

	logi.logiWrite(0x0013, (128, 0x00)) # set failsafe value for speed
	logi.logiWrite(0x0012, (128, 0x00)) # set current value for speed
	P = 30.0
	I = 0.75
	D = -2.0

	target_speed = 3.5
	old_error = 0.0
	integral = 0.0
	while True:
        	logi.logiWrite(0x0000, (0x01, 0x01))
        	speed = speed_service.getSpeed()
        	error = (target_speed - speed)
        	derivative = error - old_error
        	old_error = error
        	cmd = error * P + derivative * D + integral * I
        	#print "speed : "+str(speed)+"m/s , error :"+str(error)+", deriv :"+str(derivative)+", integral :"+str(integral)
        	integral = integral + error
		if cmd < 0.0 :
                	cmd = 0
        	if cmd > 127.0:
                	cmd = 127
        	logi.logiWrite(0x0012, (int(cmd)+128, 0x00))
		time.sleep(0.02)
	
	
