//DEFINE WHICH TESTS TO RUN
#define TEST_SDRAM 	
#define TEST_LED	
#define TEST_PMOD_1_2
#ifdef LOGIPI
#define TEST_PMOD_3_4
#endif
#define TEST_SW
#define TEST_PB		
#define TEST_COMM	
#define TEST_LVDS 	



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

#define LED_MASK 0x0003
#define PB_MASK 0x0003
#define SW_MASK 0x000C
#define SDRAM_ERROR_MASK 0x0010
#define SDRAM_SUCCESS_MASK 0x0020

#define SATA_WRITE_SHIFT 2
#define SATA_READ_SHIFT 6

#define GPIO_TEST1_DIR 0x5555	
#define GPIO_TEST1_1 0x1111
#define GPIO_TEST1_2 0x4444

#define GPIO_TEST2_DIR 0xAAAA	
#define GPIO_TEST2_1 0x2222
#define GPIO_TEST2_2 0x8888
#endif


#ifdef LOGIBONE

#define LOAD_CMD "/usr/bin/logi_loader logibone_test.bit"
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

#define LED_MASK 0x0003
#define PB_MASK 0x0003
#define SW_MASK 0x000C
#define SDRAM_ERROR_MASK 0x0010
#define SDRAM_SUCCESS_MASK 0x0020

#define SATA_WRITE_SHIFT 2
#define SATA_READ_SHIFT 6

#define GPIO_TEST1_DIR 0x5555	
#define GPIO_TEST1_1 0x1111
#define GPIO_TEST1_2 0x4444

#define GPIO_TEST2_DIR 0xAAAA	
#define GPIO_TEST2_1 0x2222
#define GPIO_TEST2_2 0x8888

#endif

