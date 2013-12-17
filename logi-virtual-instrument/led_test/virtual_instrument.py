#!/usr/bin/env python

import pygame, sys, random, os
#import logipi
'''import constants used by pygame such as event type = QUIT'''
from pygame.locals import * 


'''Initialize pygame components'''
pygame.init()

'''
Centres the pygame window. Note that the environment variable is called 
SDL_VIDEO_WINDOW_POS because pygame uses SDL (standard direct media layer)
for it's graphics, and other functions
'''
os.environ['SDL_VIDEO_WINDOW_POS'] = 'center'

'''Set the window title'''
pygame.display.set_caption("Virtual Panel")

'''Initialize a display with width 370 and height 542 with 32 bit colour'''
screen = pygame.display.set_mode((800, 293), 0, 32)

'''Create variables with image names we will use'''
backgroundfile = "breadboard_800x293.png"
crosshairsfile = "finger_point_100.png"
led_file_0 = "led_clear_final.png"	#led image for logic 0
led_file_1 = "led_blue.png"		#led image for logic 1
dip_sw8_file = "dip_sw_8_300.png"
push_button_file = "push_button_75.png"

#load dip sw files
sw_background_file = "./dip_sw8_all/sw8_background.png"
sw1_h_file = "./dip_sw8_all/sw1_h.png"
sw2_h_file = "./dip_sw8_all/sw2_h.png"
sw3_h_file = "./dip_sw8_all/sw3_h.png"
sw4_h_file = "./dip_sw8_all/sw4_h.png"
sw5_h_file = "./dip_sw8_all/sw5_h.png"
sw6_h_file = "./dip_sw8_all/sw6_h.png"
sw7_h_file = "./dip_sw8_all/sw7_h.png"
sw8_h_file = "./dip_sw8_all/sw8_h.png"
sw1_l_file = "./dip_sw8_all/sw1_l.png"
sw2_l_file = "./dip_sw8_all/sw2_l.png"
sw3_l_file = "./dip_sw8_all/sw3_l.png"
sw4_l_file = "./dip_sw8_all/sw4_l.png"
sw5_l_file = "./dip_sw8_all/sw5_l.png"
sw6_l_file = "./dip_sw8_all/sw6_l.png"
sw7_l_file = "./dip_sw8_all/sw7_l.png"
sw8_l_file = "./dip_sw8_all/sw8_l.png"


'''Convert images to a format that pygame understands'''
background = pygame.image.load(backgroundfile).convert()
'''Convert alpha means we use the transparency in the pictures that support it'''
mouse = pygame.image.load(crosshairsfile).convert_alpha()
led_high= pygame.image.load(led_file_1).convert_alpha()
led_low = pygame.image.load(led_file_0).convert_alpha()
dip_sw8 = pygame.image.load(dip_sw8_file).convert_alpha()
push_button = pygame.image.load(push_button_file).convert_alpha()
#Convert the sw8 background and switche variables
sw_background = pygame.image.load(sw_background_file).convert_alpha()
sw1_l = pygame.image.load(sw1_l_file).convert_alpha()
sw2_l = pygame.image.load(sw2_l_file).convert_alpha()
sw3_l = pygame.image.load(sw3_l_file).convert_alpha()
sw4_l = pygame.image.load(sw4_l_file).convert_alpha()
sw5_l = pygame.image.load(sw5_l_file).convert_alpha()
sw6_l = pygame.image.load(sw6_l_file).convert_alpha()
sw7_l = pygame.image.load(sw7_l_file).convert_alpha()
sw8_l = pygame.image.load(sw8_l_file).convert_alpha()
sw1_h = pygame.image.load(sw1_h_file).convert_alpha()
sw2_h = pygame.image.load(sw2_h_file).convert_alpha()
sw3_h = pygame.image.load(sw3_h_file).convert_alpha()
sw4_h = pygame.image.load(sw4_h_file).convert_alpha()
sw5_h = pygame.image.load(sw5_h_file).convert_alpha()
sw6_h = pygame.image.load(sw6_h_file).convert_alpha()
sw7_h = pygame.image.load(sw7_h_file).convert_alpha()
sw8_h = pygame.image.load(sw8_h_file).convert_alpha()

'''Used to manage how fast the screen updates'''
clock = pygame.time.Clock()

'''before we start the main section, hide the mouse cursor'''
#pygame.mouse.set_visible(False)
pygame.mouse.set_visible(True)

#location of the virtual peripherals
LED_Y = 20
LED1_X = 350
LED2_X = 400
LED3_X = 450
LED4_X = 500
LED5_X = 550
LED6_X = 600
LED7_X = 650
LED8_X = 700

SW8_X = 10
SW8_Y = 25
#dip switch states 
sw1 = 0
sw2 = 0
sw3 = 0
sw4 = 0
sw5 = 0
sw6 = 0
sw7 = 0
sw8 = 0


PB1_X = 10
PB2_X = 85
PB3_X = 160
PB4_X = 235
PB_Y = 150

#local variables
count = 0
switches = 0


'''How many pixels to move the pi image across the screen'''
#pispeed = 10
pispeed = 1
count = 0


while True:
	
	'''The code below quits the program if the X button is pressed'''
	for event in pygame.event.get():
		if event.type == QUIT:
			pygame.quit()
			sys.exit()
			
			
	'''Draw the background image on the screen'''
	screen.blit(background, (0,0))
	screen.blit(sw_background, (SW8_X,SW8_Y))
	#draw push buttons
	screen.blit(push_button, (PB1_X,PB_Y))
	#screen.blit(push_button, (PB2_X,PB_Y))
	#screen.blit(push_button, (PB3_X,PB_Y))
	#screen.blit(push_button, (PB4_X,PB_Y))
	
	
	'''determine the value of each led and set high or low image'''
	if (count & 0x80) :
		screen.blit(sw1_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw1_l, (SW8_X,SW8_Y))
	if (count & 0x40) :
		screen.blit(sw2_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw2_l, (SW8_X,SW8_Y))
	if (count & 0x20) :
		screen.blit(sw3_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw3_l, (SW8_X,SW8_Y))
	if (count & 0x10) :
		screen.blit(sw4_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw4_l, (SW8_X,SW8_Y))
	if (count & 0x08) :
		screen.blit(sw5_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw5_l, (SW8_X,SW8_Y))
	if (count & 0x04) :
		screen.blit(sw6_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw6_l, (SW8_X,SW8_Y))
	if (count & 0x02) :
		screen.blit(sw7_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw7_l, (SW8_X,SW8_Y))
	if (count & 0x01) :
		screen.blit(sw8_h, (SW8_X,SW8_Y))
	else :
		screen.blit(sw8_l, (SW8_X,SW8_Y))
	
	
	'''determine the value of each led and set high or low image'''
	if (count & 0x80) :
		screen.blit(led_high, (LED1_X ,LED_Y))
	else :
		screen.blit(led_low, (LED1_X ,LED_Y))	
	if (count & 0x40) :
		screen.blit(led_high, (LED2_X ,LED_Y))
	else :
		screen.blit(led_low, (LED2_X ,LED_Y))
	if (count & 0x20) :
		screen.blit(led_high, (LED3_X ,LED_Y))
	else :
		screen.blit(led_low, (LED3_X ,LED_Y))
	if (count & 0x10) :
		screen.blit(led_high, (LED4_X ,LED_Y))
	else :
		screen.blit(led_low, (LED4_X ,LED_Y))
	if (count & 0x08) :
		screen.blit(led_high, (LED5_X ,LED_Y))
	else :
		screen.blit(led_low, (LED5_X ,LED_Y))
	if (count & 0x04) :
		screen.blit(led_high, (LED6_X ,LED_Y))
	else :
		screen.blit(led_low, (LED6_X ,LED_Y))
	if (count & 0x02) :
		screen.blit(led_high, (LED7_X ,LED_Y))
	else :
		screen.blit(led_low, (LED7_X ,LED_Y))
	if (count & 0x01) :
		screen.blit(led_high, (LED8_X ,LED_Y))
	else :
		screen.blit(led_low, (LED8_X ,LED_Y))

						
	'''Now we have initialized everything, lets start with the main part'''
	
	'''Get the co ordinate for the edges of the screen'''
	screenboundx, screenboundy = screen.get_size()
	'''Get the X and Y mouse positions to variables called x and y'''
	mousex,mousey = pygame.mouse.get_pos()
	
	print "mouse x" , mousex
	print "mouse y" , mousey
	
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
	clock.tick(10)
	count += 1
	#count = logipi.directRead(0x00, 2)[0]
	'''Finish off by update the full display surface to the screen'''
	pygame.display.update()
