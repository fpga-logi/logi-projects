import logi
import time


line_pos = [0] * 320

def switch_laser(s = 1, on = 1):
	
	logi.logiWrite(0x1003, (0x01, 0x00))
	pin = logi.logiRead(0x1002, 2)
	if s == 1:
		lower_byte = pin[0] ^ 0x01
	else :
		if on == 0:
			lower_byte = pin[0] | 0x01
		else:
			lower_byte = pin[0] & (~0x01)
	logi.logiWrite(0x1002, (lower_byte, pin[1]))



def calibrate_line():
	for i in range(100):
		pos = logi.logiRead(0x2000, 320*2)
		for j in range(320):
			posy = pos[j*2] + (pos[j*2+1] << 8)
			line_pos[j] = line_pos[j] + posy
		time.sleep(0.03)

	for j in range(320):
                line_pos[j] = line_pos[j]/100
	print line_pos

def detect_objects():
	pos = logi.logiRead(0x2000, 320*2)
	objects = []
	no_obj = True
	last_object_id = 0
	for i in range(320):
		posy = pos[i*2] + (pos[i*2+1] << 8)
		posy = posy - line_pos[i]
		if abs(posy) > 15:
			if no_obj :
				objects.append([i, posy])
				no_obj = False
			else:
				if i <= objects[last_object_id][0]+objects[last_object_id][1]:
					objects[last_object_id][1] = objects[last_object_id][1]+1
				else:
					objects.append([i, 1])
					last_object_id = last_object_id + 1
	#print objects
	obj_list = []
	for obj in objects:
		if obj[1] > 10:
			obj_list.append([obj[0]+(obj[1]/2), obj[1]])
	return obj_list

if __name__ == "__main__":
	calibrate_line()
	while True:
		print detect_objects()
		time.sleep(1)		
