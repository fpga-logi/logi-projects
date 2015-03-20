//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN
//#define TEST_SOUND		//test the sound output
#define TEST_VGA		//test the vga output
#define TEST_IO		//test the onboard IO
#define TEST_SSEG 		//test the SSEG

#ifdef LOGIPI
#define LOG_PATH "/home/pi/tests_log/%ld_test.log"
#define LOAD_CMD "/usr/bin/logi_loader logi_edu_test.bit"


#define GPIO0 0x0000	//GPIO0 (PMOD4) WB ADDRESS 
#define GPIO0DIR 0x0001
#define SSEG_0 0x0004	//SSEGX4 WB ADDRESS

//NOTES FOR THE GPIO TEST R1.0 and R1.1
/*--SHORTS - PASS THROUGH CONNECTIONS ON PMOD PORT4
pwm2	<-> pwm1 		= p4_0	<->  p4_6   //
nesclk 	<-> nes_data2 	= p4_1	<->	 p4_3
neslat 	<-> nes_data1  	= p4_2	<->	 p4_7
ps2c_1 	<-> ps2d_1		= p4_4	<->	 p4_5 */ //


//R1.0 and R1.1
#define GPIO_TEST1_DIR 0x0056			//IO tristate direction 1 = output, P4_1, P4_2, P4_4, P4_6 as outputs	
#define GPIO_TEST1_1 0x00012			//values assigned to output pins, testing P4_4, P4_1 
#define GPIO_TEST1_1_EXPECTED 0xFF28	//pattern received at the input pins P4_3, P4_5 should be high
#define GPIO_TEST1_2 0x0044				// testing P4_2, P4_6
#define GPIO_TEST1_2_EXPECTED 0xFF81    //P4_7, P4_0 should be high

#define GPIO_TEST2_DIR 0x00A9 			//IO tristate direction 1 = output, P4_5, P4_7, P4_3, P4_0 as outputs	
#define GPIO_TEST2_1 0x0088 			// testing P4_3, P4_7
#define GPIO_TEST2_1_EXPECTED 0xFF06 	// P4_2 P4_1 high
#define GPIO_TEST2_2 0x0021 			// testing P4_5, P4_0
#define GPIO_TEST2_2_EXPECTED 0xFF50 	// P4_4, P4_6 high






#endif



