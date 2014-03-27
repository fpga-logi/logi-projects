//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN
#define TEST_SSEG 		//test the SSEG
#define TEST_SOUND		//test the sound output



#ifdef LOGIPI

#define LOAD_CMD "/usr/bin/logi_loader logi_edu_test.bit"
#define SSEG_0 0x0008

#define LOG_PATH "/home/pi/tests_log/%ld_test.log"

#endif



