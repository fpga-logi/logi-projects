import logi
import time
from binascii import *
from string import *



while True:
	time.sleep(0.1)
	logi.logiWrite(0x0004, (0xFF, 0xFF))
	for i in range(3):
		sonar = logi.logiRead(0x0010+i, 2)
		sonar_tp = (sonar[1] << 8) | sonar[0]
		sonar_cm = float(sonar_tp)/59.0
		print "sonar "+str(i)+" :"+str(sonar_cm)+" cm"
