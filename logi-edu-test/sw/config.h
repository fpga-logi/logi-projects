//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN
#define TEST_SSEG 		//test the SSEG
#define TEST_SOUND		//test the sound output
#define TEST_IO		//test the onboard IO
#define TEST_VGA		//test the vga output


#ifdef LOGIPI

#define LOAD_CMD "/usr/bin/logi_loader logi_edu_test.bit"
#define SSEG_0 0x0004
#define GPIO0 0x0000
#define GPIO0DIR 0x0001


#define GPIO_TEST1_DIR 0x0055	
#define GPIO_TEST1_1 0x0011
#define GPIO_TEST1_1_EXPECTED 0x0028
#define GPIO_TEST1_2 0x0044
#define GPIO_TEST1_2_EXPECTED 0x0082

#define GPIO_TEST2_DIR 0x00AA
#define GPIO_TEST2_1 0x0022
#define GPIO_TEST2_1_EXPECTED 0x0041
#define GPIO_TEST2_2 0x0088
#define GPIO_TEST2_2_EXPECTED 0x0014

#define LOG_PATH "/home/pi/tests_log/%ld_test.log"

#endif



