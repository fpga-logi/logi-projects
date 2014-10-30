

import logi
import time
import random

MAT_ADDR = 0x0400

def bufferFromPixels(pixels):
        buffer = [0]*2048
        i = 0
        for p in pixels:
                buffer[i] = p & 0x00FF
                buffer[i+1] = p >> 8
                i = i + 2
        return tuple(buffer)

map = ()
count = 0
for c in range(1024):
	r = count << 8 
	map = map + (r & 0xFF, ((r >> 8) & 0xFF))
	count = count + 1
	if count > 15:
		count = 0
logi.logiWrite(MAT_ADDR, map)

time.sleep(1)

map = ()
g = 0x00F0
count = 0
for c in range(1024):
        g = count << 4
	map = map + (g & 0xFF, ((g >> 8) & 0xFF))
	count = count + 1
        if count > 15:
                count = 0
logi.logiWrite(MAT_ADDR, map)

time.sleep(1)

b = 0x000F
map = ()
count = 0
for c in range(1024):
	b = count
        map = map + (b & 0xFF, ((b >> 8) & 0xFF))
	count = count + 1
        if count > 15:
                count = 0
logi.logiWrite(MAT_ADDR, map)

time.sleep(1)

i=0

while i < 1024 :
	map = [0] * 2048
       	map[i*2] = 0xFF
	map[(i*2)+1] = 0xFF 
	logi.logiWrite(MAT_ADDR, tuple(map))
	#time.sleep(0.01)	
	i = i + 1

map = ()
equ = 0
for c in range(1024):
        if c == equ:
                map = map + (0xFF, 0xFF)
		equ = equ + 33
        else:
                map = map + (0x00, 0x00)
logi.logiWrite(MAT_ADDR, map)

time.sleep(1)

pos = [0, 0]
vec = [0.35, 0.12]
col = 0x000F

while True:
	pixels = [0]*1024
	for i in range(1024):
		pixels[i] = random.randint(0, 2048)
	logi.logiWrite(MAT_ADDR, bufferFromPixels(pixels))
	

while True:
	pixels = [0]*1024
	pixels[int(pos[0])*32+int(pos[1])] = col
	pos[0] = pos[0]+vec[0]
	pos[1] = pos[1]+vec[1]
	if pos[0] >= 31 :
		vec[0] = -vec[0]
		pos[0] = 31
		col = col << 4
	if pos[0] <= 0 :
		vec[0] = -vec[0]
		pos[0] = 0
		col = col << 4
	if pos[1] >= 31 :
                vec[1] = -vec[1]
		pos[1] = 31
		col = col << 4
        if pos[1] <= 0 :
                vec[1] = -vec[1]
		pos[1] = 0
		col = col << 4
	if col == 0xF000:
		col = 0x000F
	#print pos
	logi.logiWrite(MAT_ADDR, bufferFromPixels(pixels))
