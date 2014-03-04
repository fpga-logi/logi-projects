//DEFINE WHICH TESTS TO RUN
#define TEST_SDRAM 	
#define TEST_LED	
#define TEST_PMOD_1_2
#ifdef LOGIPI
#define TEST_PMOD_3_4
#define TEST_RPI_GPIO
#endif
#define TEST_SW
#define TEST_PB		
#define TEST_COMM	
#define TEST_LVDS 	
#define TEST_ARD


#ifdef OLD_TEST


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


#else

#define GPIO_TEST1_DIR 0x5555	
#define GPIO_TEST1_1 0x1111
#define GPIO_TEST1_1_EXPECTED 0x2828
#define GPIO_TEST1_2 0x4444
#define GPIO_TEST1_2_EXPECTED 0x8282

#define GPIO_TEST2_DIR 0xAAAA
#define GPIO_TEST2_1 0x2222
#define GPIO_TEST2_1_EXPECTED 0x4141
#define GPIO_TEST2_2 0x8888
#define GPIO_TEST2_2_EXPECTED 0x1414


#endif


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


//1-2-3-1-2-3

#define ARD_MASK 0x003F
#define ARD_TEST1_DIR 0x0015	
#define ARD_TEST1_1 0x0011
#define ARD_TEST1_1_EXPECTED 0x000A
#define ARD_TEST1_2 0x0004
#define ARD_TEST1_2_EXPECTED 0x0020

#define ARD_TEST2_DIR 0x002A	
#define ARD_TEST2_1 0x0022
#define ARD_TEST2_1_EXPECTED 0x0014
#define ARD_TEST2_2 0x0008
#define ARD_TEST2_2_EXPECTED 0x0001

#define LOG_PATH "/home/pi/tests_log/%ld_test.log"

#endif


#ifdef LOGIBONE

#define LOAD_CMD "dd if=./logibone_test.bit of=/dev/logibone bs=4M"
#define GPIO0 0x0004
#define GPIO0DIR 0x0006
#define GPIO1 0x0008
#define GPIO1DIR 0x000A
#define GPIO2 0x000C
#define GPIO2DIR 0x000E
#define REG0  0x0020
#define REG1  0x0022
#define REG2  0x0024
#define REG_DEBUG_RAM 0x0026
#define MEM0  0x2000


//1-2-3-1-2-3

#define ARD_MASK 0x003F
#define ARD_TEST1_DIR 0x0015	
#define ARD_TEST1_1 0x0011
#define ARD_TEST1_1_EXPECTED 0x000A
#define ARD_TEST1_2 0x0004
#define ARD_TEST1_2_EXPECTED 0x0020

#define ARD_TEST2_DIR 0x002A	
#define ARD_TEST2_1 0x0022
#define ARD_TEST2_1_EXPECTED 0x0014
#define ARD_TEST2_2 0x0008
#define ARD_TEST2_2_EXPECTED 0x0001

#define LOG_PATH "/home/ubuntu/tests_log/%ld_test.log"

#endif



