#!/usr/bin/env python

import pygame, sys, random, os, time
#import logipi
'''import constants used by pygame such as event type = QUIT'''
from pygame.locals import * 

#DEFINES
USE_FINGER_POINTER = 0
OUTPUT_MOUSE_LOCATION_DATA = 0

'''Initialize pygame components'''
pygame.init()

'''Centres the pygame window. '''
os.environ['SDL_VIDEO_WINDOW_POS'] = 'center'

'''Set the window title'''
pygame.display.set_caption("Virtual Panel")

'''Initialize a display with width 370 and height 542 with 32 bit colour'''
screen = pygame.display.set_mode((800, 293), 0, 32)

'''Create variables'''
backgroundfile = "./img/brd/breadboard_800x293.png"
crosshairsfile = "./img/finger/finger_point_100.png"
led_file_0 = "./img/led/led_clear_final.png"	#led image for logic 0
led_file_1 = "./img/led/led_blue_final.png"		#led image for logic 1
push_button_file = "./img/pb/push_button_75.png"

#load dip sw files
sw_background_file = "./img/sw/sw8_background.png"
sw1_h_file = "./img/sw/sw1_h.png"
sw2_h_file = "./img/sw/sw2_h.png"
sw3_h_file = "./img/sw/sw3_h.png"
sw4_h_file = "./img/sw/sw4_h.png"
sw5_h_file = "./img/sw/sw5_h.png"
sw6_h_file = "./img/sw/sw6_h.png"
sw7_h_file = "./img/sw/sw7_h.png"
sw8_h_file = "./img/sw/sw8_h.png"
sw1_l_file = "./img/sw/sw1_l.png"
sw2_l_file = "./img/sw/sw2_l.png"
sw3_l_file = "./img/sw/sw3_l.png"
sw4_l_file = "./img/sw/sw4_l.png"
sw5_l_file = "./img/sw/sw5_l.png"
sw6_l_file = "./img/sw/sw6_l.png"
sw7_l_file = "./img/sw/sw7_l.png"
sw8_l_file = "./img/sw/sw8_l.png"


'''Convert images to a format that pygame understands'''
background = pygame.image.load(backgroundfile).convert()
'''Convert alpha means we use the transparency in the pictures that support it'''
mouse = pygame.image.load(crosshairsfile).convert_alpha()
led_high= pygame.image.load(led_file_1).convert_alpha()
led_low = pygame.image.load(led_file_0).convert_alpha()
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

#MOUSE VISIBLE OR NOT?
#pygame.mouse.set_visible(False)
pygame.mouse.set_visible(True)

#LED LOCATIONS
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

#SWITCH BODY LOCATION LOCATION
SW8_X = 10
SW8_Y = 25
#FIGURING OUT THE PIXEL DISTANCE FOR SW HOTSPOTS
#EDGE TO FIRST NUB = 15
#FIRST SW LEFT SIDE TO FAR RIGHT SW RIGHT SIDE = TOTAL ACTIVE X DISTANCE = 295 - 15 = 280 
#280 / NUMBER OF LOCATIONS = 8 => 280/8 = 35 : NEED TO FUDGE = 36 WORKS WELL
#START = SW8_X + EDGE TO FIRST NUB/2 = 10 + 7.5 = 
SW_EDGE_TO_NUB = 15
SW_HOTSPOT_DX = 36

SW_HOTSPOT_X1 = SW8_X + SW_EDGE_TO_NUB/2
SW_HOTSPOT_X2 = SW_HOTSPOT_X1 + SW_HOTSPOT_DX
SW_HOTSPOT_X3 = SW_HOTSPOT_X2 + SW_HOTSPOT_DX
SW_HOTSPOT_X4 = SW_HOTSPOT_X3 + SW_HOTSPOT_DX
SW_HOTSPOT_X5 = SW_HOTSPOT_X4 + SW_HOTSPOT_DX
SW_HOTSPOT_X6 = SW_HOTSPOT_X5 + SW_HOTSPOT_DX
SW_HOTSPOT_X7 = SW_HOTSPOT_X6 + SW_HOTSPOT_DX
SW_HOTSPOT_X8 = SW_HOTSPOT_X7 + SW_HOTSPOT_DX
SW_HOTSPOT_X9 = SW_HOTSPOT_X8 + SW_HOTSPOT_DX

SW_HOTSPOT_Y0 = 50
SW_HOTSPOT_Y1 = 115



#dip switch states 
sw1_state = 0
sw2_state = 0
sw3_state = 0
sw4_state = 0
sw5_state = 0
sw6_state = 0
sw7_state = 0
sw8_state = 0

#PUSH BUTTONLOCATIONS
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
sw_val = 0

#DEFAULT SWITCH VALUES
screen.blit(sw1_l, (SW8_X,SW8_Y))
screen.blit(sw2_l, (SW8_X,SW8_Y))
screen.blit(sw3_l, (SW8_X,SW8_Y))
screen.blit(sw4_l, (SW8_X,SW8_Y))
screen.blit(sw5_l, (SW8_X,SW8_Y))
screen.blit(sw6_l, (SW8_X,SW8_Y))
screen.blit(sw7_l, (SW8_X,SW8_Y))
screen.blit(sw8_l, (SW8_X,SW8_Y))


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

	#GET THE MOUSE LOCATION
	'''Get the co ordinate for the edges of the screen'''
	screenboundx, screenboundy = screen.get_size()
	'''Get the X and Y mouse positions to variables called x and y'''
	mousex,mousey = pygame.mouse.get_pos()
		
	if OUTPUT_MOUSE_LOCATION_DATA == 1:
		print "mouse x" , mousex
		print "mouse y" , mousey
		
	##TODO: NEED TO ADD A TIME SCHEDULE THE SWITCH CHECK IN ORDER TO NOT RE-ENTRY AND NOT CLOCK THE PROGRAM
	#CAN REMOVE THE DELAY AFTER SETTING UP THE SCHEDULED CHECK
	#CHECK FOR MOUSE CLICK AND IF IN BOUNDS OF SWITCH - THIS IS WHERE THE SWITCHED WILL CHANGE STATES
	if event.type == MOUSEBUTTONDOWN:
		#print "mouse click check"
		#print SW_HOTSPOT_X1, " ", SW_HOTSPOT_X2
		if (mousex >= SW_HOTSPOT_X1 and mousex <= SW_HOTSPOT_X2) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw1 clicked"
			sw1_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X2 and mousex <= SW_HOTSPOT_X3) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw2 clicked"
			sw2_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X3 and mousex <= SW_HOTSPOT_X4) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw3 clicked"
			sw3_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X4 and mousex <= SW_HOTSPOT_X5) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw4 clicked"
			sw4_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X5 and mousex <= SW_HOTSPOT_X6) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw5 clicked"
			sw5_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X6 and mousex <= SW_HOTSPOT_X7) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw6 clicked"
			sw6_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X7 and mousex <= SW_HOTSPOT_X8) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw7 clicked"
			sw7_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY
		if (mousex >= SW_HOTSPOT_X8 and mousex <= SW_HOTSPOT_X9) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
			print "sw8 clicked"
			sw8_state ^= 1
			time.sleep(.001)	#NEED A DELAY TO KEEP FROM RE-ENTRY

			
	#UPDATE THE CURRENT STATE OF THE SW HERE, OR IT WILL NOT BE DRAWN		
	if sw1_state :
		screen.blit(sw1_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw1_l, (SW8_X,SW8_Y))
	if sw2_state :
		screen.blit(sw2_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw2_l, (SW8_X,SW8_Y))
	if sw3_state :
		screen.blit(sw3_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw3_l, (SW8_X,SW8_Y))
	if sw4_state :
		screen.blit(sw4_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw4_l, (SW8_X,SW8_Y))
	if sw5_state :
		screen.blit(sw5_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw5_l, (SW8_X,SW8_Y))
	if sw6_state :
		screen.blit(sw6_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw6_l, (SW8_X,SW8_Y))
	if sw7_state :
		screen.blit(sw7_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw7_l, (SW8_X,SW8_Y))
	if sw8_state :
		screen.blit(sw8_h, (SW8_X,SW8_Y))	
	else:
		screen.blit(sw8_l, (SW8_X,SW8_Y))
		
	#calcualte the new switch value:
	sw_val = (sw1_state<<7) | (sw2_state<<6) | sw3_state<<5 | sw4_state<<4 | sw5_state<<3 | sw6_state<<2 | sw7_state<<1 | sw8_state
	print "switch value: ", sw_val
	

	
	#UPDATE THE LED DATA
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

											
	
	'''
	x -= mousewidth  x = x - mousewidth
	Take half of the width of the limage from the mouse co-ordinate
	So the mouse is in the middle of the image
	'''
	mousex -= mouse.get_width()/2
	mousey -= 10

	
	'''Draw the crosshairs to the screen at the co ordinates we just worked out'''
	if USE_FINGER_POINTER :
		screen.blit(mouse, (mousex,mousey))
	
	
	# if event.type == MOUSEBUTTONDOWN:
		# '''The mouse has been clicked so see if the sprites rectangles collide
		# The pygame.sprite.collide_rect returns either True or False.
		# Note that in our case the collision detection isn't very accurate
		# because there will be a collision even if the edge of the crosshairs
		# is over the edge of the pi. This can be improved by testing collision 
		# on specific pixels which I will do next week'''
		
		# #hit = pi.rect.collidepoint(crosshairs.rect.centerx, crosshairs.rect.centery)
		
		# #if hit == True:
			# #'''The crosshairs was over the pi sprite when mouse was clicked'''
			# #score.value += 1
	
	'''Limit screen updates to 20 frames per second so we dont use 100% cpu time'''
	#clock.tick(20)
	clock.tick(10)
	count += 1
	#count = logipi.directRead(0x00, 2)[0]
	'''Finish off by update the full display surface to the screen'''
	pygame.display.update()
