
from socket import *



HOST = '127.0.1.1'
PORT = 2045    #our port from before
ADDR = (HOST,PORT)
BUFSIZE = 4096

cli = socket( AF_INET,SOCK_STREAM)
cli.connect((ADDR))

cli.send('{ "steer" : 30.0, "time" : 2000.0, "speed" : 40 }')
cli.send('{ "steer" : 0.0, "time" : 1000.0, "speed" : 0 }')
cli.send('{ "steer" : -30.0, "time" : 2000.0, "speed" : -40 }')

cli.close()
