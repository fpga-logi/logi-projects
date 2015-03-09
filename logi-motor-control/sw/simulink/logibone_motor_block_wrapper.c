

/*
 * Include Files
 *
 */
#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
#include "rtwtypes.h"
#endif

/* %%%-SFUNWIZ_wrapper_includes_Changes_BEGIN --- EDIT HERE TO _END */
#ifndef MATLAB_MEX_FILE
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#endif
/* %%%-SFUNWIZ_wrapper_includes_Changes_END --- EDIT HERE TO _BEGIN */
#define u_width 1
#define y_width 1
/*
 * Create external references here.  
 *
 */
/* %%%-SFUNWIZ_wrapper_externs_Changes_BEGIN --- EDIT HERE TO _END */
#ifndef MATLAB_MEX_FILE
int fd;
unsigned short readVal;
unsigned short writeVal;
#endif
/* %%%-SFUNWIZ_wrapper_externs_Changes_END --- EDIT HERE TO _BEGIN */

/*
 * Output functions
 *
 */
void logibone_motor_block_Outputs_wrapper(const uint16_T *duty1,
			const uint16_T *duty2,
			const uint16_T *period,
			const boolean_T *reset_cnt1,
			const boolean_T *reset_cnt2,
			const boolean_T *dir1,
			const boolean_T *dir2,
			uint16_T *cnt1,
			uint16_T *cnt2,
			uint16_T *spd1,
			uint16_T *spd2,
			const real_T *xD)
{
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_BEGIN --- EDIT HERE TO _END */
if (xD[0] == 1){
#ifndef MATLAB_MEX_FILE
  //write pwm values
  pwrite(fd, period, 2, 0x0005);  
  pwrite(fd, duty1, 2, 0x0006);
  pwrite(fd, duty2, 2, 0x0007);
  //write direction - don't bother preserving previous value
  writeVal = 0;
  if(dir1[0]) writeVal = 0x1;
  if(dir2[0]) writeVal |= 0x0100;
  pwrite(fd, &writeVal, 2, 0x0001);
      
  //read encoder counts
  pread(fd, &readVal, 2, 0x0000);
  cnt1[0] = readVal;
  pread(fd, &readVal, 2, 0x0001);
  cnt2[0] = readVal;  
  //read encoder speeds - not yet implemented in bitstream
  //pread(fd, &readVal, 2, 0x0000);
  spd1[0] = 0;
  //pread(fd, &readVal, 2, 0x0001);
  spd2[0] = 0;  
#endif
}
/* This sample sets the output equal to the input
      y0[0] = u0[0]; 
 For complex signals use: y0[0].re = u0[0].re; 
      y0[0].im = u0[0].im;
      y1[0].re = u1[0].re;
      y1[0].im = u1[0].im;
*/
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_END --- EDIT HERE TO _BEGIN */
}

/*
  * Updates function
  *
  */
void logibone_motor_block_Update_wrapper(const uint16_T *duty1,
			const uint16_T *duty2,
			const uint16_T *period,
			const boolean_T *reset_cnt1,
			const boolean_T *reset_cnt2,
			const boolean_T *dir1,
			const boolean_T *dir2,
			const uint16_T *cnt1,
			const uint16_T *cnt2,
			const uint16_T *spd1,
			const uint16_T *spd2,
			real_T *xD)
{
  /* %%%-SFUNWIZ_wrapper_Update_Changes_BEGIN --- EDIT HERE TO _END */
if (xD[0] == 0){
  xD[0] = 1;
  #ifndef MATLAB_MEX_FILE
  fd = open("/dev/logibone_mem", O_RDWR | O_SYNC);
  #endif
}


/*
 * Code example
 *   xD[0] = u0[0];
*/
/* %%%-SFUNWIZ_wrapper_Update_Changes_END --- EDIT HERE TO _BEGIN */
}
