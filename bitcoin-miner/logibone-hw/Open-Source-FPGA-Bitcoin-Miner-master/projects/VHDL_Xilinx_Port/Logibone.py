import fcntl, os, time, mmap, struct


RESETA_INDEX = 12
RESETB_INDEX = 10
SIZE_INDEX = 8
AVAILABLE_INDEX = 12
FREE_INDEX = 10
STATE_INDEX = 16
RES_LSB_INDEX = 18
RES_MSB_INDEX = 20
DATA_LSB1_INDEX = 22
DATA_LSB2_INDEX = 24
DATA_MSB1_INDEX = 26
DATA_MSB2_INDEX = 28
LATCH_LOOP_INDEX = 30
GPMC_OFFSET = 0x09000000

sha_test = [0x22, 0x8e, 0xa4, 0x73, 0x2a, 0x3c, 0x9b, 0xa8, 0x60, 0xc0, 0x09, 0xcd, 0xa7, 0x25, 0x2b, 0x91, 0x61, 0xa5, 0xe7, 0x5e, 0xc8, 0xc5, 0x82, 0xa5, 0xf1, 0x06, 0xab, 0xb3, 0xaf, 0x41, 0xf7, 0x90]
sha_data = [0x21, 0x94, 0x26, 0x1a, 0x93, 0x95, 0xe6, 0x4d, 0xbe, 0xd1, 0x71, 0x15]


class Logibone:
	
	def __init__(self):
		if os.path.exists('/dev/logibone0'):
    			self.file = open('/dev/logibone0', 'r+')
		else:
			self.file = -1
			MAP_MASK = mmap.PAGESIZE - 1
			with open("/dev/mem", "r+b" ) as self.mem:
				self.gpmc = mmap.mmap(self.mem.fileno(), mmap.PAGESIZE, offset=GPMC_OFFSET)		
	def read(self, nbBytes):
		if self.file > 0 :
			return self.file.read(nbBytes)
		else:
			result = [];
			for i in range(nbBytes/2):
				longVal =  struct.unpack("<H",self.gpmc[0:2])
				print longVal
				result.append(longVal[0] & 0x00FF)
				result.append((longVal[0] >> 8) & 0x00FF)
			return result

	def write(self, val):
		if self.file > 0 :
			return self.file.write(val)
		else:
			print 'writing '+str(len(val))+' bytes'
			for i in range(0, len(val), 2):
				longVal = (val[i] << 8)+val[i+1] # transferred MSB first
				self.gpmc[0:2] = struct.pack("<H", longVal)

	def reset(self):
		if self.file > 0 :
			fcntl.ioctl(self.file, 0)
		else:
			self.gpmc[RESETA_INDEX:RESETA_INDEX+2] = struct.pack("<H", 0)
			self.gpmc[RESETB_INDEX:RESETB_INDEX+2] = struct.pack("<H", 0)


	def writeLoop(self, val):
		self.gpmc[LATCH_LOOP_INDEX:LATCH_LOOP_INDEX+2] = struct.pack("<H", val)
		#self.gpmc[LATCH_LOOP_INDEX:LATCH_LOOP_INDEX+2] = struct.pack("<H", (val & 0xFFFF))
	def readLoop(self):
		ret = struct.unpack("<H", self.gpmc[LATCH_LOOP_INDEX:LATCH_LOOP_INDEX+2])
		return ret[0]
	def getSize(self):
			ret = struct.unpack("<H",self.gpmc[SIZE_INDEX:SIZE_INDEX+2])
			return ret[0]
	def getFree(self):
		ret = struct.unpack("<H", self.gpmc[FREE_INDEX:FREE_INDEX+2])	
		return (self.getSize()- ret[0])

	def getAvailable(self):
		ret = struct.unpack("<H", self.gpmc[AVAILABLE_INDEX:AVAILABLE_INDEX+2])	
		return ret[0]

	def readState(self):
		ret = struct.unpack("<H", self.gpmc[STATE_INDEX:STATE_INDEX+2])	
		state = []		
		state.append(ret[0]>>10)
		state.append((ret[0]>>2) & 0x00FF)
		state.append(ret[0] & 0x0001) # error
		state.append((ret[0]>>1) & 0x0001)# hit !	
		return state

	def readResult(self):
		retLsb = struct.unpack("<H", self.gpmc[RES_LSB_INDEX:RES_LSB_INDEX+2])
		retMsb = struct.unpack("<H", self.gpmc[RES_MSB_INDEX:RES_MSB_INDEX+2])	
		result = []
		result.append((retMsb[0] >> 8) & 0x00FF)
		result.append(retMsb[0] & 0x00FF)
		result.append((retLsb[0] >> 8) & 0x00FF)		
		result.append(retLsb[0] & 0x00FF)
		return result
	
	def readData(self):
		retLsb1 = struct.unpack("<H", self.gpmc[DATA_LSB1_INDEX:DATA_LSB1_INDEX+2])
		retLsb2 = struct.unpack("<H", self.gpmc[DATA_LSB2_INDEX:DATA_LSB2_INDEX+2])
		retMsb1 = struct.unpack("<H", self.gpmc[DATA_MSB1_INDEX:DATA_MSB1_INDEX+2])
		retMsb2 = struct.unpack("<H", self.gpmc[DATA_MSB2_INDEX:DATA_MSB2_INDEX+2])		
		result = []			
		result.append(retLsb1[0] & 0x00FF)
		result.append((retLsb1[0] >> 8) & 0x00FF)
		result.append(retLsb2[0] & 0x00FF)
		result.append((retLsb2[0] >> 8) & 0x00FF)
		result.append(retMsb1[0] & 0x00FF)
		result.append((retMsb1[0] >> 8) & 0x00FF)
		result.append(retMsb2[0] & 0x00FF)
		result.append((retMsb2[0] >> 8) & 0x00FF)
		return result

	def close(self):
		if self.file > 0 :
			self.file.close();		
		else:
			self.gpmc.close()
			os.close(self.mem)

if __name__ == "__main__":
	bone = Logibone()
	try:	
		#bone.writeLoop(0x55AA)
		bone.reset()		
		print bone.getSize()
		print bone.getFree()
		bone.write(sha_test)
		bone.write(sha_data)	
		#print bone.readData()
		#print hex(bone.readLoop())
		status = bone.readState()
		while status[3] == 0:
			bone.getAvailable()
			status = bone.readState()
			print status
			print bone.readResult()
			time.sleep(5)
		print bone.readResult()
	except KeyboardInterrupt:
		print("Terminated by Ctrl+C")
		exit(0)

