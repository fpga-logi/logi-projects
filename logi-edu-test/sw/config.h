//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN
//#define TEST_SOUND		//test the sound output
//#define TEST_VGA		//test the vga output
#define TEST_IO		//test the onboard IO
#define TEST_SSEG 		//test the SSEG

#ifdef LOGIPI
#define LOG_PATH "/home/pi/tests_log/%ld_test.log"
#define LOAD_CMD "/usr/bin/logi_loader logi_edu_test.bit"


#define GPIO0 0x0000	//GPIO0 (PMOD4) WB ADDRESS 
#define GPIO0DIR 0x0001
#define SSEG_0 0x0004	//SSEGX4 WB ADDRESS

//NOTES FOR THE GPIO TEST:
/*--SHORTS - PASS THROUGH CONNECTIONS ON PMOD PORT4
pwm2	<-> pwm1 		= p4_0	<->  p4_4  
nesclk 	<-> nes_data2 	= p4_1	<->	 p4_3
neslat 	<-> nes_data1  	= p4_2	<->	 p4_7
ps2c_1 	<-> ps2d_1		= p4_4	<->	 p4_5 */ // P4_4 is shorted twice
//TEST PMOD4 DIRECTION1
//direction 		= 0bxxxx xxxx 0001 0111 = 0x0017
//output pattern 	= 0bxxxx xxxx 0001 0111	= 0x0017
//expected read  	= 0bxxxx xxxx 1110 1000	= 0x00E8

//TEST PMOD4 DIRECTION2
//direction 		= 0bxxxx xxxx 1110 1000 = 0xE8
//output pattern 	= 0bxxxx xxxx 1110 1000	= 0xE8
//expected read  	= 0bxxxx xxxx 0001 0111	= 0x17

#define GPIO_TEST1_DIR 0x0007		//IO tristate direction 1 = output, P4_0, P4_1, P4_2 as outputs	
#define GPIO_TEST1_1 0x0007		//values assigned to output pins 
#define GPIO_TEST1_1_EXPECTED 0x00B8	//pattern received at the input pins P4_3, P4_4, P4_5, P4_7 should be high
#define GPIO_TEST1_2 0x0007		// test_2 is same direction different pattern, we don't need it in this case
#define GPIO_TEST1_2_EXPECTED 0x00B0

#define GPIO_TEST2_DIR 0x00E8 //IO tristate direction 1 = output, P4_5, P4_6, P4_7, P4_3 as outputs	
#define GPIO_TEST2_1 0x00E8
#define GPIO_TEST2_1_EXPECTED 0x0013
#define GPIO_TEST2_2 0x00E8
#define GPIO_TEST2_2_EXPECTED 0x0013


#endif



