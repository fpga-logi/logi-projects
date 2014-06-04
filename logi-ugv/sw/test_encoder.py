import logi
import time
from binascii import *
from string import *

logi.logiWrite(0x0003, (0x01, 0x01))
logi.logiWrite(0x0003, (0x00, 0x00))
while True:
	enc_reg = logi.logiRead(0x0003, 2)
	enc_val = (enc_reg[1] << 8) | enc_reg[0]
	print enc_val
	time.sleep(0.1)
