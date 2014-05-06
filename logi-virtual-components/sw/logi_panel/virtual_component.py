#!/usr/bin/env python

import pygame, sys, random, os , time

'''import constants used by pygame such as event type = QUIT'''
from pygame.locals import * 

#DEFINES
USE_WINDOWS = 0
WINDOWS_UPDATE_COUNT = 0
USE_FINGER_POINTER = 0
OUTPUT_MOUSE_LOCATION_DATA = 0
DEBUG = 0
USE_FRAMEBUFFER = 0
SLEEP_TIME = .001

if USE_WINDOWS==0 :
	from logi import *

if USE_FRAMEBUFFER :
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
else:
	'''Initialize pygame components'''
	pygame.init()
	'''Centres the pygame window. '''
	os.environ['SDL_VIDEO_WINDOW_POS'] = 'center'
	'''Set the window title'''
	pygame.display.set_caption("Virtual Panel")
	'''Initialize a display with width 370 and height 542 with 32 bit colour'''
	screen = pygame.display.set_mode((800, 293), 0, 32)
	pygame.display.update()


'''Create variables'''
backgroundfile = "./img/brd/breadboard_800x293.png"
crosshairsfile = "./img/finger/finger_point_100.png"

#LED VARIALBES
led_file_0 = "./img/led/led_clear_final.png"	#led image for logic 0
led_file_1 = "./img/led/led_blue_final.png"		#led image for logic 1
#LED LOCATIONS
#location of the virtual peripherals
LED_Y = 20
LEDX_SPACING = 50
LED1_X = 375
LED2_X = LED1_X + LEDX_SPACING
LED3_X = LED2_X + LEDX_SPACING
LED4_X = LED3_X + LEDX_SPACING
LED5_X = LED4_X + LEDX_SPACING
LED6_X = LED5_X + LEDX_SPACING
LED7_X = LED6_X + LEDX_SPACING
LED8_X = LED7_X + LEDX_SPACING

#PUSH BUTTON VARIALBLES
pb_h_file = "./img/pb/pb_pushed_75.png"
pb_l_file = "./img/pb/pb_npushed_75.png"


PB_X_SPACING = 75
PB1_X = 10
PB2_X = PB1_X + PB_X_SPACING
PB3_X = PB2_X + PB_X_SPACING
PB4_X = PB3_X + PB_X_SPACING
PB_Y = 175
PB_Y_SPACING = 70

pb1_state = 0
pb2_state = 0
pb3_state = 0
pb4_state = 0

#!!!! THESE VALUES ARE GETTING MESSED UP SOMEWHERE.  HARD CODED FOR NOW
PB_HOTSPOT_X1 = PB1_X
PB_HOTSPOT_X2 = 85
PB_HOTSPOT_X3 = 160
PB_HOTSPOT_X4 = 235
PB_HOTSPOT_X5 = 310	
#PB_HOTSPOT_X2 = PB_HOTSPOT_X1 + PB_X_SPACING #290
#PB_HOTSPOT_X3 = PB_HOTSPOT_X2 + PB_X_SPACING
#PB_HOTSPOT_X4 = PB_HOTSPOT_X3 + PB_X_SPACING

PB_HOTSPOT_Y1 = PB_Y
PB_HOTSPOT_Y2 = PB_Y + PB_Y_SPACING

#DIP SWITCH VARIABLES *****************************
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

#SSEG VARIABLES ********************************************
sseg_back_file = "./img/sseg/sseg_back_100.png"
sega_file = "./img/sseg/sega_100.png"
segb_file = "./img/sseg/segb_100.png"
segc_file = "./img/sseg/segc_100.png"
segd_file = "./img/sseg/segd_100.png"
sege_file = "./img/sseg/sege_100.png"
segf_file = "./img/sseg/segf_100.png"
segg_file = "./img/sseg/segg_100.png"
segp_file = "./img/sseg/segp_100.png"

SSEG_WIDTH = 70
SSEG_SPACE = 2

SSEG1_X = 500	#aligned with LED
SSEG2_X = SSEG1_X + SSEG_WIDTH + SSEG_SPACE	
SSEG3_X = SSEG2_X + SSEG_WIDTH + SSEG_SPACE	
SSEG4_X = SSEG3_X + SSEG_WIDTH + SSEG_SPACE	
SSEG_Y = 150

#CONVERT IMAGES *********************************************
'''Convert images to a format that pygame understands'''
background = pygame.image.load(backgroundfile).convert()
'''Convert alpha means we use the transparency in the pictures that support it'''
mouse = pygame.image.load(crosshairsfile).convert_alpha()
led_high= pygame.image.load(led_file_1).convert_alpha()
led_low = pygame.image.load(led_file_0).convert_alpha()
#PUSH BUTTON IMAGES
pb_h = pygame.image.load(pb_h_file).convert_alpha()
pb_l = pygame.image.load(pb_l_file).convert_alpha()
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
#CONVERT SSEG IMAGES
sseg_back = pygame.image.load(sseg_back_file).convert_alpha()
sega = pygame.image.load(sega_file).convert_alpha()
segb = pygame.image.load(segb_file).convert_alpha()
segc = pygame.image.load(segc_file).convert_alpha()
segd = pygame.image.load(segd_file).convert_alpha()
sege = pygame.image.load(sege_file).convert_alpha()
segf = pygame.image.load(segf_file).convert_alpha()
segg = pygame.image.load(segg_file).convert_alpha()
segp = pygame.image.load(segp_file).convert_alpha()

#DO STUFF *******************************************************
'''Used to manage how fast the screen updates'''
clock = pygame.time.Clock()

#MOUSE VISIBLE OR NOT?
#pygame.mouse.set_visible(False)
pygame.mouse.set_visible(True)

count = 0
#CONTROL VARIABLES ************************************************

#DIP SWITCH VALUE
sw_val = 0
#SSEG values - WRITE
sseg1_val = 0x7c 	# 0b01111100 = b
sseg2_val = 0x79 	# 0b01111001 = e		
sseg3_val = 0x79 	# 0b01111001 = e
sseg4_val = 0x71 	# 0b01110001 = f

#SWITCH VALUES
sw1_state = 0
sw2_state = 0
sw3_state = 0
sw4_state = 0

#DEFAULT SWITCH VALUES VIEW
screen.blit(sw1_l, (SW8_X,SW8_Y))
screen.blit(sw2_l, (SW8_X,SW8_Y))
screen.blit(sw3_l, (SW8_X,SW8_Y))
screen.blit(sw4_l, (SW8_X,SW8_Y))
screen.blit(sw5_l, (SW8_X,SW8_Y))
screen.blit(sw6_l, (SW8_X,SW8_Y))
screen.blit(sw7_l, (SW8_X,SW8_Y))
screen.blit(sw8_l, (SW8_X,SW8_Y))

mouse_click_processed = 0  #default value

while True:
	
	'''The code below quits the program if the X button is pressed'''
	for event in pygame.event.get():
		if event.type == QUIT:
			pygame.quit()
			sys.exit()
			

			
	'''DEFAULT BACKGROUND IMAGES'''
	screen.blit(background, (0,0))
	screen.blit(sw_background, (SW8_X,SW8_Y))
	#draw push buttons BACKGROUND
	screen.blit(pb_l, (PB1_X,PB_Y))	#being updated based on state below
	screen.blit(pb_l, (PB2_X,PB_Y))
	screen.blit(pb_l, (PB3_X,PB_Y))
	screen.blit(pb_l, (PB4_X,PB_Y))
	#DRAW SSEGS BACKGROUND
	screen.blit(sseg_back, (SSEG1_X,SSEG_Y))	#SSEG1 DRAW
	screen.blit(sseg_back, (SSEG2_X,SSEG_Y))	#SSEG1 DRAW
	screen.blit(sseg_back, (SSEG3_X,SSEG_Y))	#SSEG1 DRAW
	screen.blit(sseg_back, (SSEG4_X,SSEG_Y))	#SSEG1 DRAW
	
	
		# pick a font you have and set its size
	myfont = pygame.font.SysFont("Arial", 24)
	myfont.set_bold(1)
	# apply it to text on a label
	label = myfont.render("SW VAL %u" % sw_val, 1, (0,0,0))
	screen.blit(label, (100, -2))


	#GET THE MOUSE LOCATION
	'''Get the co ordinate for the edges of the screen'''
	screenboundx, screenboundy = screen.get_size()
	'''Get the X and Y mouse positions to variables called x and y'''
	mousex,mousey = pygame.mouse.get_pos()
		
	if OUTPUT_MOUSE_LOCATION_DATA == 1 or DEBUG == 1:
		print "mouse x" , mousex
		print "mouse y" , mousey
		
	'''Draw the crosshairs to the screen at the co ordinates we just worked out'''
	if USE_FINGER_POINTER :
		screen.blit(mouse, (mousex,mousey))
		mousex -= mouse.get_width()/2
		# mousey -= 10
		
	##TODO: NEED TO ADD A TIME SCHEDULE THE SWITCH CHECK IN ORDER TO NOT RE-ENTRY AND NOT CLOCK THE PROGRAM
	#CAN REMOVE THE DELAY AFTER SETTING UP THE SCHEDULED CHECK
	#CHECK FOR MOUSE CLICK AND IF IN BOUNDS OF SWITCH - THIS IS WHERE THE SWITCHED WILL CHANGE STATES
	if event.type == MOUSEBUTTONDOWN:
		#CHECK FOR ALL HOTPOST COMPONENT LOCATIONS PUSHED
		if mouse_click_processed == 0  :
			if (mousex >= SW_HOTSPOT_X1 and mousex <= SW_HOTSPOT_X2) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw1 clicked"
				sw1_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X2 and mousex <= SW_HOTSPOT_X3) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw2 clicked"
				sw2_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X3 and mousex <= SW_HOTSPOT_X4) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw3 clicked"
				sw3_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X4 and mousex <= SW_HOTSPOT_X5) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw4 clicked"
				sw4_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X5 and mousex <= SW_HOTSPOT_X6) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw5 clicked"
				sw5_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X6 and mousex <= SW_HOTSPOT_X7) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw6 clicked"
				sw6_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X7 and mousex <= SW_HOTSPOT_X8) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw7 clicked"
				sw7_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
			elif (mousex >= SW_HOTSPOT_X8 and mousex <= SW_HOTSPOT_X9) and (mousey >= SW_HOTSPOT_Y0 and mousey <= SW_HOTSPOT_Y1):
				if DEBUG ==1 :
					print "sw8 clicked"
				sw8_state ^= 1
				mouse_click_processed = 1  #set flag that the button down was processed
	
			#CHECK FOR PUSHBOTTON PUSHED
			if (mousex >= 10 and mousex <= 85) and (mousey >= PB_HOTSPOT_Y1 and mousey <= PB_HOTSPOT_Y2):
				if DEBUG ==1 :
					print "pb1 pushed"
				pb1_state = 1	#state need to release in button up event
				if pb1_state :
					screen.blit(pb_h, (PB1_X,PB_Y))	
			#elif (mousex >= PB_HOTSPOT_X2 and mousex <= SW_HOTSPOT_X3) and (mousey >= PB_HOTSPOT_Y1 and mousey <= PB_HOTSPOT_Y2):
			elif (mousex >= 85 and mousex <= 160) and (mousey >= PB_HOTSPOT_Y1 and mousey <= PB_HOTSPOT_Y2):
				if DEBUG ==1 :
					print "pb2 pushed"
				pb2_state = 1	#state need to release in button up event
				if pb2_state :
					screen.blit(pb_h, (PB2_X,PB_Y))
			elif (mousex >= 160 and mousex <= 235) and (mousey >= PB_HOTSPOT_Y1 and mousey <= PB_HOTSPOT_Y2):
				if DEBUG ==1 :
					print "pb3 pushed"
				pb3_state = 1	#state need to release in button up event
				if pb3_state :
					screen.blit(pb_h, (PB3_X,PB_Y))	
			elif (mousex >= 235 and mousex <= 310) and (mousey >= PB_HOTSPOT_Y1 and mousey <= PB_HOTSPOT_Y2):
				if DEBUG ==1 :
					print "pb4 pushed"
				pb4_state = 1	#state need to release in button up event
				if pb4_state :
					screen.blit(pb_h, (PB4_X,PB_Y))	
	#update pb_val with all buttons
	pb_val	= pb1_state<<3 | pb2_state<<2 | pb3_state<<1 | pb4_state
	if DEBUG:
		print "pb_value: " , pb_val
	
	if event.type == MOUSEBUTTONUP:
		mouse_click_processed = 0	#wait for mouse button to go up before re-running the button down process
		#release pushbuttons here if they were pushed
		if pb1_state == 1 :	#if the pb state was previously pushed
			pb1_state = 0
		if pb2_state == 1 :	#if the pb state was previously pushed
			pb2_state = 0
		if pb3_state == 1 :	#if the pb state was previously pushed
			pb3_state = 0
		if pb4_state == 1 :	#if the pb state was previously pushed
			pb4_state = 0
		#screen.blit(pb_l, (PB1_X,PB_Y))	
		
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
		
		
	#UPDATE STATE OF THE PB	
	# if pb1_state :
		# screen.blit(pb_h, (PB1_X,PB_Y))	
	# else:
		# screen.blit(pb_l, (PB1_X,PB_Y))
		
	#calcualte the new switch value:
	sw_val = (sw1_state<<7) | (sw2_state<<6) | sw3_state<<5 | sw4_state<<4 | sw5_state<<3 | sw6_state<<2 | sw7_state<<1 | sw8_state
	if DEBUG ==1 :
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

	
	#LOAD THE SSEG DATA
	#SSEG1
	if(sseg1_val>>0 & 0x01) :#low bit high
		screen.blit(sega, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>1 & 0x01) :
		screen.blit(segb, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>2 & 0x01) :
		screen.blit(segc, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>3 & 0x01) :
		screen.blit(segd, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>4 & 0x01) :
		screen.blit(sege, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>5 & 0x01) :
		screen.blit(segf, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>6 & 0x01) :
		screen.blit(segg, (SSEG1_X ,SSEG_Y))
	if(sseg1_val>>7 & 0x01) :
		screen.blit(segp, (SSEG1_X ,SSEG_Y))
	
	#SSEG2
	if(sseg2_val>>0 & 0x01) :#low bit high
		screen.blit(sega, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>1 & 0x01) :
		screen.blit(segb, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>2 & 0x01) :
		screen.blit(segc, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>3 & 0x01) :
		screen.blit(segd, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>4 & 0x01) :
		screen.blit(sege, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>5 & 0x01) :
		screen.blit(segf, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>6 & 0x01) :
		screen.blit(segg, (SSEG2_X ,SSEG_Y))
	if(sseg2_val>>7 & 0x01) :
		screen.blit(segp, (SSEG2_X ,SSEG_Y))
	
	#SSEG3
	if(sseg3_val>>0 & 0x01) :#low bit high
		screen.blit(sega, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>1 & 0x01) :
		screen.blit(segb, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>2 & 0x01) :
		screen.blit(segc, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>3 & 0x01) :
		screen.blit(segd, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>4 & 0x01) :
		screen.blit(sege, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>5 & 0x01) :
		screen.blit(segf, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>6 & 0x01) :
		screen.blit(segg, (SSEG3_X ,SSEG_Y))
	if(sseg3_val>>7 & 0x01) :
		screen.blit(segp, (SSEG3_X ,SSEG_Y))
	
	#SSEG4
	if(sseg4_val>>0 & 0x01) :#low bit high
		screen.blit(sega, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>1 & 0x01) :
		screen.blit(segb, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>2 & 0x01) :
		screen.blit(segc, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>3 & 0x01) :
		screen.blit(segd, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>4 & 0x01) :
		screen.blit(sege, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>5 & 0x01) :
		screen.blit(segf, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>6 & 0x01) :
		screen.blit(segg, (SSEG4_X ,SSEG_Y))
	if(sseg4_val>>7 & 0x01) :
		screen.blit(segp, (SSEG4_X ,SSEG_Y))

	#UPDATE THE DISPLAY
	pygame.display.update()
	
		#WISHBONE MEMORY MAP
		# 0x0000 LEDs
		# 0x0001 SW
		# 0x0008 SSEG0
		# 0x0009 SSEG1
		# 0x000A SSEG2
		# 0x000B SSEG3
		# 0x000C SSEG4
		# 0x000D SSEG5
		# 0x000E SSEG6
		# 0x000F SSEG7
		# 0x0010 PB -- PB(0) is wired to reset
	
	if USE_WINDOWS==0 :
		count = logiRead(0x00, 2)[0]
		logiWrite(0x01, (sw_val, 0x00))
		logiWrite(0x10, (pb_val, 0x00))
		#update sseg
		sseg1_val = logiRead(0x08, 2)[0] # SSEG 0
		sseg2_val = logiRead(0x08, 2)[1] #SSEG 1
		sseg3_val = logiRead(0x09, 2)[0] # SSEG 2
		sseg4_val = logiRead(0x09, 2)[1] # SSEG 3
	else:
		if WINDOWS_UPDATE_COUNT:
			count += 1  #AUTO INCREMENT
			sseg1_val += 1
			sseg2_val += 1
			sseg3_val += 1
			sseg4_val += 1
		else:
			count = 0xAA
			
		
	#count = logipi.directRead(0x00, 2)[0]	#READ VALUES FROM LOGIPI
	
	time.sleep(SLEEP_TIME)	#SLOW DOWN THE LOOP
