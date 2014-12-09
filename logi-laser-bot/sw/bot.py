import sys
sys.path.append("/home/ubuntu/logi-tools/python/") 
import logi_hal, math
import time
import laser


GPIO_ADDR = 0x1002
PWM_ADDR = 0x1004

class Bot:
	pwm_period = 0x0800
	dir_mask = [2, 4]
	wheel_base = 0.09
	def __init__(self):
		logi_hal.setGPIODir(GPIO_ADDR, 0x0007)
		logi_hal.setGPIOVal(GPIO_ADDR, 0x0006)
		logi_hal.setPWMDivider(PWM_ADDR, 0x003F)
		logi_hal.setPWMPeriod(PWM_ADDR, self.pwm_period)
		
	def setWheelSpeed(self, index, speed):
		if index == 0:
			speed = -speed
		pwm_val = math.fabs(speed) * self.pwm_period
		pwm_val = int(pwm_val)
		if pwm_val > self.pwm_period:
			pwm_val = self.pwm_period
		if(speed < 0):
			gpio_val = logi_hal.getGPIOVal(GPIO_ADDR)
			gpio_val &= ~self.dir_mask[index]
			logi_hal.setGPIOVal(GPIO_ADDR, gpio_val)
		else:
			gpio_val = logi_hal.getGPIOVal(GPIO_ADDR)
                        gpio_val |= (self.dir_mask[index])
                        logi_hal.setGPIOVal(GPIO_ADDR, gpio_val)
		logi_hal.setPWMPulse(PWM_ADDR, index, pwm_val)
	
	def setRadius(self, radius, velocity):
		angular_speed = velocity/(radius+(self.wheel_base/2))
		speed_left = radius * angular_speed
		speed_right = (radius+self.wheel_base) * angular_speed
		if radius > 0:
			self.setWheelSpeed(0, speed_left)
			self.setWheelSpeed(1, speed_right)
		else:
			self.setWheelSpeed(1, speed_left)
                        self.setWheelSpeed(0, speed_right)

if __name__ == "__main__":
	middle = 160
	time.sleep(5)
	laser.switch_laser(0, 1)
	laser.calibrate_line()
	time.sleep(0.5)
	bot = Bot()
	#bot.setRadius(40.0, 0.00)
	bot.setWheelSpeed(0, 0.0)
	bot.setWheelSpeed(1, 0.0)
	print "Pause bot"
	time.sleep(2)
	bot.setWheelSpeed(0, 0.30)
	bot.setWheelSpeed(1, 0.30)
	
	while True:	
		time.sleep(0.1)
		objs = laser.detect_objects()
		print objs
		if len(objs) == 0:
			bot.setWheelSpeed(0, 0.35)
                	bot.setWheelSpeed(1, 0.35)
		else:
			for obj in objs:
				if obj[0] > 30 and obj[0] < 290:
					bot.setWheelSpeed(0, 0.0)
					bot.setWheelSpeed(1, 0.0)
				 
