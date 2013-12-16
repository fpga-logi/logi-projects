#!/usr/bin/env python

import pygame, sys, random, os
import logipi
'''import constants used by pygame such as event type = QUIT'''
from pygame.locals import * 

'''Initialize pygame components'''
#pygame.init()

'''
Centres the pygame window. Note that the environment variable is called 
SDL_VIDEO_WINDOW_POS because pygame uses SDL (standard direct media layer)
for it's graphics, and other functions
'''
#os.environ['SDL_VIDEO_WINDOW_POS'] = 'center'

'''Set the window title'''
#pygame.display.set_caption("Virtual Panel")

'''Initialize a display with width 370 and height 542 with 32 bit colour'''
#screen = pygame.display.set_mode((800, 600), 0, 32)

"Ininitializes a new pygame screen using the framebuffer"
# Based on "Python GUI in Linux frame buffer"
# http://www.karoltomala.com/blog/?p=679
disp_no = os.getenv("DISPLAY")
if disp_no:
	print "I'm running under X display = {0}".format(disp_no)
# Check which frame buffer drivers are available
# Start with fbcon since directfb hangs with composite output
drivers = ['fbcon', 'directfb', 'svgalib']
found = False
for driver in drivers:
# Make sure that SDL_VIDEODRIVER is set
	if not os.getenv('SDL_VIDEODRIVER'):
		os.putenv('SDL_VIDEODRIVER', driver)
	try:
		pygame.display.init()
	except pygame.error:
		print 'Driver: {0} failed.'.format(driver)
		continue
	found = True
	break
if not found:
	raise Exception('No suitable video driver found!')
size = (pygame.display.Info().current_w, pygame.display.Info().current_h)
print "Framebuffer size: %d x %d" % (size[0], size[1])
screen = pygame.display.set_mode(size, pygame.FULLSCREEN)
# Clear the screen to start
screen.fill((0, 0, 0))
# Initialise font support
#pygame.font.init()
# Render the screen
pygame.display.update()


'''Create variables with image names we will use'''
backgroundfile = "breadboard_800x293.png"
crosshairsfile = "finger_point_100.png"
pifile = "led_blue.png"
led_file_0 = "led_clear.png"	#led image for logic 0
led_file_1 = "led_blue.png"		#led image for logic 1
dip_sw8_file = "dip_sw_8_300.png"

screen.fill((64, 64, 64))
'''Convert images to a format that pygame understands'''
background = pygame.image.load(backgroundfile).convert()

'''Convert alpha means we use the transparency in the pictures that support it'''
mouse = pygame.image.load(crosshairsfile).convert_alpha()
pi = pygame.image.load(pifile).convert_alpha()
led_high= pygame.image.load(led_file_1).convert_alpha()
led_low = pygame.image.load(led_file_0).convert_alpha()

dip_sw8 = pygame.image.load(dip_sw8_file).convert_alpha()


'''Used to manage how fast the screen updates'''
clock = pygame.time.Clock()

'''before we start the main section, hide the mouse cursor'''
#pygame.mouse.set_visible(False)
pygame.mouse.set_visible(True)

'''create variables to hold where the Pi logo is'''
pix = -50
piy = 60

LED_Y = 20
LED1_X = 350
LED2_X = 400
LED3_X = 450
LED4_X = 500
LED5_X = 550
LED6_X = 600
LED7_X = 650
LED8_X = 700

LED2_Y = 120


DIP_SW8_X = 10
DIP_SW8_Y = 25


'''How many pixels to move the pi image across the screen'''
#pispeed = 10
pispeed = 1


count = 0
switches = 0

while True:
	
	'''The code below quits the program if the X button is pressed'''
	for event in pygame.event.get():
		if event.type == QUIT:
			pygame.quit()
			sys.exit()
			
			
	'''Draw the background image on the screen'''
	screen.blit(background, (0,0))
	screen.blit(dip_sw8, (DIP_SW8_X,DIP_SW8_Y))
	

	if (switches & 0x000001) :
                screen.blit(led_high, (LED1_X ,LED2_Y))
        else :
                screen.blit(led_low, (LED1_X ,LED2_Y))

	if (switches & 0x000002) :
                screen.blit(led_high, (LED2_X ,LED2_Y))
        else :
                screen.blit(led_low, (LED2_X ,LED2_Y))

	
	if (switches & 0x000004) :
                screen.blit(led_high, (LED3_X ,LED2_Y))
        else :
                screen.blit(led_low, (LED3_X ,LED2_Y))

	if (count & 0x000080) :
		screen.blit(led_high, (LED1_X ,LED_Y))
	else :
		screen.blit(led_low, (LED1_X ,LED_Y))	
	if (count & 0x000040) :
		screen.blit(led_high, (LED2_X ,LED_Y))
	else :
		screen.blit(led_low, (LED2_X ,LED_Y))
	if (count & 0x000020) :
		screen.blit(led_high, (LED3_X ,LED_Y))
	else :
		screen.blit(led_low, (LED3_X ,LED_Y))
	if (count & 0x000010) :
		screen.blit(led_high, (LED4_X ,LED_Y))
	else :
		screen.blit(led_low, (LED4_X ,LED_Y))
	if (count & 0x000008) :
		screen.blit(led_high, (LED5_X ,LED_Y))
	else :
		screen.blit(led_low, (LED5_X ,LED_Y))
	if (count & 0x000004) :
		screen.blit(led_high, (LED6_X ,LED_Y))
	else :
		screen.blit(led_low, (LED6_X ,LED_Y))
	if (count & 0x000002) :
		screen.blit(led_high, (LED7_X ,LED_Y))
	else :
		screen.blit(led_low, (LED7_X ,LED_Y))
	if (count & 0x000001) :
		screen.blit(led_high, (LED8_X ,LED_Y))
	else :
		screen.blit(led_low, (LED8_X ,LED_Y))

						
	'''Now we have initialized everything, lets start with the main part'''
	
	'''Get the co ordinate for the edges of the screen'''
	screenboundx, screenboundy = screen.get_size()
	'''Get the X and Y mouse positions to variables called x and y'''
	mousex,mousey = pygame.mouse.get_pos()
	
	#print "mouse x" , mousex
	#print "mouse y" , mousey
	
	'''
	x -= mousewidth  x = x - mousewidth
	Take half of the width of the limage from the mouse co-ordinate
	So the mouse is in the middle of the image
	'''
	mousex -= mouse.get_width()/2
	mousey -= 10

	
	'''Draw the crosshairs to the screen at the co ordinates we just worked out'''
	screen.blit(mouse, (mousex,mousey))
	
	'''Limit screen updates to 20 frames per second so we dont use 100% cpu time'''
	#clock.tick(20)
	clock.tick(20)
	#count += 1
	(count, switches) = logipi.directRead(0x00, 2)
	#print count
	'''Finish off by update the full display surface to the screen'''
	pygame.display.update()
