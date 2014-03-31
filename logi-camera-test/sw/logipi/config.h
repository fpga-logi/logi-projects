//DEFINE WHICH TESTS TO RUN
//COMMENT OUT TESTS YOU DO NOT WANT TO RUN

#ifdef LOGIPI

#define LOAD_CMD "/usr/bin/logi_loader logi_camera_test.bit"

#define FIFO_ADDR 0x0000
#define FIFO_CMD_OFFSET 0x0004
#define FIFO_SIZE_OFFSET 0x0004
#define FIFO_AVAILABLE_OFFSET 0x00041

#define LOG_PATH "/home/pi/tests_log/%ld_test.log"

#endif



