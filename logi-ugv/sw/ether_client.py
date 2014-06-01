
from socket import *



HOST = '127.0.1.1'
PORT = 2045    #our port from before
ADDR = (HOST,PORT)
BUFSIZE = 4096

cli = socket( AF_INET,SOCK_STREAM)
cli.connect((ADDR))

cli.send('{ "steer" : -10.0, "time" : 3000.0, "speed" : 75 }')
cli.send('{ "steer" : -45.0, "time" : 800.0, "speed" : 75 }')
cli.send('{ "steer" : -10.0, "time" : 2000.0, "speed" : 75 }')
cli.send('{ "steer" : -45.0, "time" : 800.0, "speed" : 75 }')
cli.send('{ "steer" : -10.0, "time" : 3000.0, "speed" : 75 }')
cli.send('{ "steer" : -45.0, "time" : 800.0, "speed" : 75 }')
cli.send('{ "steer" : -10.0, "time" : 3000.0, "speed" : 0 }')

cli.close()
