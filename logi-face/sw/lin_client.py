import time


lin_file = open('/root/linphone_out')
while True:
	line = lin_file.readline()
	if line:
		if line.find("Message") != -1:
			print line.split(":")[-1]
