/*
PMOD Diagram - testing sequence

vcc gnd 3 2 1 0
vcc gnd 7 6 5 4

test jiig for PMOD test shorts upper row pins with lower row pins one by one :

- 0 & 4 are shorted
- 1 & 5 are shorted
- 2 & 6 are shorted
- 3 & 7 are shorted

First test :
 - set 0, 2 and 5, 7 as output others as inputs
 - writes '1' on 0, and 5, expect to read '1' on 1 and 4 
 - writes '1' on 2, and 7, expect to read '1' on 6 and 3

Second test :
 - set 1, 3 and 4, 6 as output others as inputs
 - writes '1' on 1, and 4, expect to read '1' on 0 and 5 
 - writes '1' on 3, and 6, expect to read '1' on 2 and 7
*/


//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN
#define TEST_SDRAM 		//test the SDRAM
#define TEST_LED		//test the leds
#define TEST_PMOD_1_2	//test pmod 1 and pmod2 (shared jig)
#ifdef LOGIPI
#define TEST_PMOD_3_4	//test pmod 3 and pmod4 (shared jig)
//#define TEST_RPI_GPIO
#endif
#define TEST_SW		//test dip switches
#define TEST_PB		//test the pushbuttons
#define TEST_COMM	//test communication between host/fpga
#define TEST_LVDS 	//testing the LVDS pins
#define TEST_ARD	//testing arduino connector pins
#define TEST_OPEN	//removing test jigs test (open)

#define LED_MASK 0x0003
#define PB_MASK 0x0003
#define SW_MASK 0x000C
#define SDRAM_ERROR_MASK 0x0010
#define SDRAM_SUCCESS_MASK 0x0020

#define SATA_WRITE_SHIFT 2
#define SATA_READ_SHIFT 6

#ifdef LOGIPI

#define LOAD_CMD "/usr/bin/logi_loader logipi_test.bit"
#define GPIO0 0x0002
#define GPIO0DIR 0x0003
#define GPIO1 0x0004
#define GPIO1DIR 0x0005
#define GPIO2 0x0006
#define GPIO2DIR 0x0007
#define REG0  0x0010
#define REG1  0x0011
#define REG2  0x0012
#define REG_DEBUG_RAM 0x0013
#define MEM0  0x1000

#define GPIO_TEST1_DIR 0xA5A5	
#define GPIO_TEST1_1 0x2121
#define GPIO_TEST1_1_EXPECTED 0x1212
#define GPIO_TEST1_2 0x8484
#define GPIO_TEST1_2_EXPECTED 0x4848

#define GPIO_TEST2_DIR 0x5A5A
#define GPIO_TEST2_1 0x1212
#define GPIO_TEST2_1_EXPECTED 0x2121
#define GPIO_TEST2_2 0x4848
#define GPIO_TEST2_2_EXPECTED 0x8484

#define ARD_MASK 0x003F
#define ARD_TEST1_DIR 0x0015	
#define ARD_TEST1_1 0x0011
#define ARD_TEST1_1_EXPECTED 0x0022
#define ARD_TEST1_2 0x0004
#define ARD_TEST1_2_EXPECTED 0x0008

#define ARD_TEST2_DIR 0x002A	
#define ARD_TEST2_1 0x0022
#define ARD_TEST2_1_EXPECTED 0x0011
#define ARD_TEST2_2 0x0008
#define ARD_TEST2_2_EXPECTED 0x0004

#define LOG_PATH "/home/pi/tests_log/%ld_test.log"

#endif



#ifdef LOGIBONE

//word aligned addressing
#define LOAD_CMD "/usr/bin/logi_loader ./logibone_test.bit"
#define GPIO0 0x0002 
#define GPIO0DIR 0x0003
#define GPIO1 0x0004
#define GPIO1DIR 0x0005
#define GPIO2 0x0006
#define GPIO2DIR 0x0007
#define REG0  0x0010
#define REG1  0x0011
#define REG2  0x0012
#define REG_DEBUG_RAM 0x0013
#define MEM0  0x1000

#define GPIO_TEST1_DIR 0xA5A5	
#define GPIO_TEST1_1 0x2121
#define GPIO_TEST1_1_EXPECTED 0x1212
#define GPIO_TEST1_2 0x8484
#define GPIO_TEST1_2_EXPECTED 0x4848

#define GPIO_TEST2_DIR 0x5A5A
#define GPIO_TEST2_1 0x1212
#define GPIO_TEST2_1_EXPECTED 0x2121
#define GPIO_TEST2_2 0x4848
#define GPIO_TEST2_2_EXPECTED 0x8484

//1-2-3-1-2-3
#define ARD_MASK 0x003F
#define ARD_TEST1_DIR 0x0015    
#define ARD_TEST1_1 0x0011
#define ARD_TEST1_1_EXPECTED 0x0022
#define ARD_TEST1_2 0x0004
#define ARD_TEST1_2_EXPECTED 0x0008


#define ARD_TEST2_DIR 0x002A    
#define ARD_TEST2_1 0x0022
#define ARD_TEST2_1_EXPECTED 0x0011
#define ARD_TEST2_2 0x0008
#define ARD_TEST2_2_EXPECTED 0x0004

#define LOG_PATH "/home/ubuntu/tests_log/%ld_test.log"

#endif



