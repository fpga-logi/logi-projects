
from socket import *



HOST = '10.0.7.2'
PORT = 2045    #our port from before
ADDR = (HOST,PORT)
BUFSIZE = 4096

cli = socket( AF_INET,SOCK_STREAM)
cli.connect((ADDR))

cli.send('{ "steer" : 30.0, "time" : 5000.0, "speed" : 45.0 }')
cli.send('{ "steer" : -30.0, "time" : 5000.0, "speed" : -45.0 }')

cli.close()
