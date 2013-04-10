import fcntl, os, time, struct, binascii
import spi


sha_test = [0x22, 0x8e, 0xa4, 0x73, 0x2a, 0x3c, 0x9b, 0xa8, 0x60, 0xc0, 0x09, 0xcd, 0xa7, 0x25, 0x2b, 0x91, 0x61, 0xa5, 0xe7, 0x5e, 0xc8, 0xc5, 0x82, 0xa5, 0xf1, 0x06, 0xab, 0xb3, 0xaf, 0x41, 0xf7, 0x90]
sha_data = [0x21, 0x94, 0x26, 0x1a, 0x93, 0x95, 0xe6, 0x4d, 0xbe, 0xd1, 0x71, 0x15]

write_cmd = 0x00

read_cmd = 0x01

class Mark1:
	
	def __init__(self):
		spi.openSPI(speed=30000000)

	def readFrom(self, addr, nb, inc):
		transfer_tuple = ()
		cmd = (addr << 2) + read_cmd + + (inc << 1)
		transfer_tuple = transfer_tuple + ((cmd >> 8),)
		transfer_tuple = transfer_tuple + ((cmd & 0x00FF),)
		transfer_tuple = transfer_tuple + tuple([0]*nb)
		data = spi.transfer(transfer_tuple)
		return list(data)[2:]

	def writeTo(self, addr, vals, inc):
		transfer_tuple = ()
		cmd = (addr << 2) + write_cmd + (inc << 1)
		transfer_tuple = transfer_tuple + ((cmd >> 8),)
		transfer_tuple = transfer_tuple + ((cmd & 0x00FF),)
		for v in vals:
			transfer_tuple = transfer_tuple + (v,)
		spi.transfer(transfer_tuple)
	
	def write(self, val):
		data_to_send = []
		for v in val:
			if isinstance(v, str):
				data_to_send.append(struct.unpack("B", v)[0])
			else:
				data_to_send.append(v)
		self.writeTo(0x00, data_to_send, 0)

	def writeLoop(self, val):
		data = [((val >> 8) & 0x00FF), (val & 0x00FF)]
		self.writeTo(0x0F, data, 0)
	def readLoop(self):
		data = self.readFrom(0x0F, 2, 0)
		return ((data[0] << 8) + data[1] )

	def readState(self):
		ret = self.readFrom(0x08, 2, 0)
		state = []		
		state.append(ret[0]>>2)
		state.append((ret[1]>>2) & 0x00FF)
		state.append(ret[1] & 0x01) # error
		state.append((ret[1]>>1) & 0x01)# hit !	
		return state

	def readResult(self):
		ret = self.readFrom(0x09,4, 1)	
		result = bytearray()	
		result.append(ret[1])
		result.append(ret[0])
		result.append(ret[3])
		result.append(ret[2])	
		return result
	
	def readData(self):
		ret = self.readFrom(0x09,8, 1)		
		return map(chr, ret)
	
	def reset(self):
		print "reset !"
	
	def close(self):
		spi.closeSPI()
	

if __name__ == "__main__":
	mark1 = Mark1()
	try:	
		mark1.writeTo(0x0000, sha_test, 0)
		mark1.writeTo(0x0000, sha_data, 0)	
		status = mark1.readState()
		while status[3] == 0:
			status = mark1.readState()
			print status
			mark1.writeLoop(0x0055)
			time.sleep(2)
			mark1.writeLoop(0x00AA)
			time.sleep(2)
		print "nonce :%s \n" % binascii.hexlify(mark1.readResult())
	except KeyboardInterrupt:
		print("Terminated by Ctrl+C")
		exit(0)

