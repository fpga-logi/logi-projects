#include <Python.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <getopt.h>
#include <errno.h>

#include "mpu9150.h"
#include "linux_glue.h"
#include "local_defaults.h"


mpudata_t mpu;
int set_cal(int mag, char *cal_file);

static void pabort(const char *s)
{
	perror(s);
	abort();
}


static PyObject* mpuInit(PyObject* self, PyObject* arg)
{
	unsigned int bus_id ;
	unsigned int rate ;
	int yaw_mix ;
	unsigned int returnVal ;
	if(!PyArg_ParseTuple(arg, "lll", &bus_id, &rate, &yaw_mix))
		return NULL;					
	returnVal = mpu9150_init(bus_id, rate, yaw_mix);	
	return Py_BuildValue("i", returnVal) ;
}

static PyObject* mpuExit(PyObject* self, PyObject* arg)
{				
	mpu9150_exit();
	return Py_BuildValue("i", 1) ;
}


static PyObject* mpuRead(PyObject* self, PyObject* arg)
{	
	int returnValue ;		
	returnValue = mpu9150_read(&mpu) ;
	return  Py_BuildValue("i", returnValue) ;
}

static PyObject* getFusedQuaternion(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	transferTuple = Py_BuildValue("(ffff)",mpu.fusedQuat[QUAT_W],mpu.fusedQuat[QUAT_X], mpu.fusedQuat[QUAT_Y],  mpu.fusedQuat[QUAT_Z]);			
	/*transferTuple = PyTuple_New(4);
	PyTuple_SetItem(transferTuple, 0, Py_BuildValue("f",mpu.fusedQuat[QUAT_W]));
	PyTuple_SetItem(transferTuple, 1, Py_BuildValue("f",mpu.fusedQuat[QUAT_X]));
	PyTuple_SetItem(transferTuple, 2, Py_BuildValue("f",mpu.fusedQuat[QUAT_Y]));
	PyTuple_SetItem(transferTuple, 3, Py_BuildValue("f",mpu.fusedQuat[QUAT_Z]));*/
	return transferTuple;
}

static PyObject* getFusedEuler(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	transferTuple = Py_BuildValue("(fff)",mpu.fusedEuler[VEC3_X] * RAD_TO_DEGREE, mpu.fusedEuler[VEC3_Y] * RAD_TO_DEGREE, mpu.fusedEuler[VEC3_Z] * RAD_TO_DEGREE );
	/*transferTuple = PyTuple_New(3);
	PyTuple_SetItem(transferTuple, 0, Py_BuildValue("f",mpu.fusedEuler[VEC3_X] * RAD_TO_DEGREE));
	PyTuple_SetItem(transferTuple, 1, Py_BuildValue("f",mpu.fusedEuler[VEC3_Y] * RAD_TO_DEGREE));
	PyTuple_SetItem(transferTuple, 2, Py_BuildValue("f",mpu.fusedEuler[VEC3_Z] * RAD_TO_DEGREE));*/
	return transferTuple;
}

static PyObject* getRawGyro(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	transferTuple = Py_BuildValue("(hhh)",mpu.rawGyro[0], mpu.rawGyro[1], mpu.rawGyro[2] );
	/*transferTuple = PyTuple_New(3);
	PyTuple_SetItem(transferTuple, 0, Py_BuildValue("f",mpu.rawGyro[0] ));
	PyTuple_SetItem(transferTuple, 1, Py_BuildValue("f",mpu.rawGyro[1] ));
	PyTuple_SetItem(transferTuple, 2, Py_BuildValue("f",mpu.rawGyro[2] ));*/
	return transferTuple;
}

static PyObject* getCalAcc(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	transferTuple = Py_BuildValue("(hhh)",mpu.calibratedAccel[0], mpu.calibratedAccel[1], mpu.calibratedAccel[2] );
	/*transferTuple = PyTuple_New(3);
	PyTuple_SetItem(transferTuple, 0, Py_BuildValue("f",mpu.calibratedAccel[0] ));
	PyTuple_SetItem(transferTuple, 1, Py_BuildValue("f",mpu.calibratedAccel[1] ));
	PyTuple_SetItem(transferTuple, 2, Py_BuildValue("f",mpu.calibratedAccel[2] ));*/
	return transferTuple;
}

static PyObject* getCalMag(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	//transferTuple = PyTuple_New(3);
	transferTuple = Py_BuildValue("(hhh)",mpu.calibratedMag[0], mpu.calibratedMag[1], mpu.calibratedMag[2] );
	/*PyTuple_SetItem(transferTuple, 0, Py_BuildValue("f",mpu.calibratedMag[0] ));
	PyTuple_SetItem(transferTuple, 1, Py_BuildValue("f",mpu.calibratedMag[1] ));
	PyTuple_SetItem(transferTuple, 2, Py_BuildValue("f",mpu.calibratedMag[2] ));*/
	return transferTuple;
}

static PyObject* setMagCal(PyObject* self, PyObject* arg)
{
	char * filePath;	
	int returnVal ;
	if(!PyArg_ParseTuple(arg, "s", &filePath))
		return NULL;
	returnVal = set_cal(1, filePath);
	return  Py_BuildValue("i", returnVal) ;
}

static PyObject* setAccCal(PyObject* self, PyObject* arg)
{
	char * filePath;	
	int returnVal ;
	if(!PyArg_ParseTuple(arg, "s", &filePath))
		return NULL;
	returnVal = set_cal(0, filePath);
	return  Py_BuildValue("i", returnVal) ;
}


int set_cal(int mag, char *cal_file)
{
	int i;
	FILE *f;
	char buff[32];
	long val[6];
	caldata_t cal;

	if (cal_file) {
		f = fopen(cal_file, "r");
		
		if (!f) {
			perror("open(<cal-file>)");
			return -1;
		}
	}
	else {
		if (mag) {
			f = fopen("./magcal.txt", "r");
		
			if (!f) {
				printf("Default magcal.txt not found\n");
				return 0;
			}
		}
		else {
			f = fopen("./accelcal.txt", "r");
		
			if (!f) {
				printf("Default accelcal.txt not found\n");
				return 0;
			}
		}		
	}

	memset(buff, 0, sizeof(buff));
	
	for (i = 0; i < 6; i++) {
		if (!fgets(buff, 20, f)) {
			printf("Not enough lines in calibration file\n");
			break;
		}

		val[i] = atoi(buff);

		if (val[i] == 0) {
			printf("Invalid cal value: %s\n", buff);
			break;
		}
	}

	fclose(f);

	if (i != 6) 
		return -1;

	cal.offset[0] = (short)((val[0] + val[1]) / 2);
	cal.offset[1] = (short)((val[2] + val[3]) / 2);
	cal.offset[2] = (short)((val[4] + val[5]) / 2);

	cal.range[0] = (short)(val[1] - cal.offset[0]);
	cal.range[1] = (short)(val[3] - cal.offset[1]);
	cal.range[2] = (short)(val[5] - cal.offset[2]);
	
	if (mag) 
		mpu9150_set_mag_cal(&cal);
	else 
		mpu9150_set_accel_cal(&cal);

	return 0;
}


static PyMethodDef mpuMethods[] =
{
	{"mpuInit", mpuInit, METH_VARARGS, "Open fifo with given i2c bus id, sampling rate and mixing val"},
	{"mpuExit", mpuExit, METH_NOARGS, "close the mpu"},
	{"mpuRead", mpuRead, METH_NOARGS, "read one sample from mpu"},
	{"getFusedQuaternion", getFusedQuaternion, METH_NOARGS, "get fused quaternion of last read"},
	{"getFusedEuler", getFusedEuler, METH_NOARGS, "get fused euler of last read"},
	{"getRawGyro", getRawGyro, METH_NOARGS, "get raw gyro of last read"},
	{"getCalAcc", getCalAcc, METH_NOARGS, "get calibrated accelerometer of last read"},
	{"getCalMag", getCalMag, METH_NOARGS, "get calibrated magnetometer of last read"},
	{"setMagCal", setMagCal, METH_VARARGS, "set the file for magnetometer calibration"},
	{"setAccCal", setAccCal, METH_VARARGS, "set the file for accelerometer calibration"},
	{NULL, NULL, 0, NULL}
};

PyMODINIT_FUNC

initmpu9150(void)
{
	(void) Py_InitModule("mpu9150", mpuMethods);
	
}
