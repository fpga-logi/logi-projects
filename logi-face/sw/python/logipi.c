#include <Python.h>
#define RPI
#include "fifolib.h"

static void pabort(const char *s)
{
	perror(s);
	abort();
}


static PyObject* fifoOpen(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	unsigned int returnVal ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	returnVal = fifo_open(fifo_id);
	return Py_BuildValue("l", returnVal) ;
}

static PyObject* fifoClose(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	fifo_close(fifo_id);
	return Py_BuildValue("l", 1) ;
}


static PyObject* fifoWrite(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	unsigned int id, returnVal ;

	if(!PyArg_ParseTuple(arg, "lO", &id, &transferTuple))
		return NULL;					

	if(!PyTuple_Check(transferTuple))			
		pabort("Only accepts a single tuple as an argument\n");


	uint32_t tupleSize = PyTuple_Size(transferTuple);
	uint8_t tx[tupleSize];
	PyObject* tempItem;
	uint32_t i=0;
	while(i < tupleSize)
	{
		tempItem = PyTuple_GetItem(transferTuple, i);		
		if(!PyInt_Check(tempItem))
		{
			pabort("non-integer contained in tuple\n");
		}
		tx[i] = (uint8_t)PyInt_AsSsize_t(tempItem);
		i++;
	}
	returnVal = fifo_write(id, tx, tupleSize);
	return Py_BuildValue("l", returnVal) ;
}


static PyObject* fifoRead(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	unsigned int id, size, i ;
	if(!PyArg_ParseTuple(arg, "ll", &id, &size))
		return NULL;					
	uint8_t rx[size];
	fifo_read(id, rx, size);
	transferTuple = PyTuple_New(size);
	for(i=0;i<size;i++)
		PyTuple_SetItem(transferTuple, i, Py_BuildValue("i",rx[i]));
	return transferTuple;
}

static PyObject* directRead(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	unsigned int offset, size, i ;
	unsigned char inc_addr = 1 ;
	if(!PyArg_ParseTuple(arg, "ll|b", &offset, &size, &inc_addr))
		return NULL;					
	uint8_t rx[size];
	if(inc_addr){
		direct_read(offset, rx, size);
	}else{
		direct_read_noinc(offset, rx, size);
	}
	transferTuple = PyTuple_New(size);
	for(i=0;i<size;i++)
		PyTuple_SetItem(transferTuple, i, Py_BuildValue("i",rx[i]));
	return transferTuple;
}

static PyObject* directWrite(PyObject* self, PyObject* arg)
{
	PyObject* transferTuple;
	unsigned int offset, returnVal ;
	unsigned char inc_addr = 1;
	if(!PyArg_ParseTuple(arg, "lO|b", &offset, &transferTuple, &inc_addr))		
		return NULL;					

	if(!PyTuple_Check(transferTuple))			
		pabort("Only accepts a single tuple as an argument\n");


	uint32_t tupleSize = PyTuple_Size(transferTuple);
	uint8_t tx[tupleSize];
	PyObject* tempItem;
	uint32_t i=0;
	while(i < tupleSize)
	{
		tempItem = PyTuple_GetItem(transferTuple, i);		//
		if(!PyInt_Check(tempItem))
		{
			pabort("non-integer contained in tuple\n");
		}
		tx[i] = (uint8_t)PyInt_AsSsize_t(tempItem);
		i++;

	}
	if(inc_addr){
		returnVal = direct_write(offset, tx, tupleSize);
	}else{
		returnVal = direct_write_noinc(offset, tx, tupleSize);
	}
	return Py_BuildValue("l", returnVal) ;
}

static PyObject* fifoReset(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	fifo_reset(fifo_id);
	return Py_BuildValue("l", 1) ;
}

static PyObject* fifoGetSize(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	unsigned int returnVal ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	returnVal = fifo_getSize(fifo_id);
	return Py_BuildValue("l", returnVal) ;
}

static PyObject* fifoGetNbFree(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	unsigned int returnVal ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	returnVal = fifo_getNbFree(fifo_id);
	return Py_BuildValue("l", returnVal) ;
}

static PyObject* fifoGetNbAvailable(PyObject* self, PyObject* arg)
{
	unsigned int fifo_id ;
	unsigned int returnVal ;
	if(!PyArg_ParseTuple(arg, "l", &fifo_id))
		return NULL;					
	returnVal = fifo_getNbAvailable(fifo_id);
	return Py_BuildValue("l", returnVal) ;
}

static PyMethodDef logipiMethods[] =
{
	{"fifoOpen", fifoOpen, METH_VARARGS, "Open fifo with given id"},
	{"fifoGetNbFree", fifoGetNbFree, METH_VARARGS, "Get nb free place in fifo with given id"},
	{"fifoGetNbAvailable", fifoGetNbAvailable, METH_VARARGS, "Get nb available token in fifo with given id"},
	{"fifoGetSize", fifoGetSize, METH_VARARGS, "Get size of fifo with given id"},
	{"fifoReset", fifoReset, METH_VARARGS, "Reset the fifo with given id"},
	{"fifoWrite", fifoWrite, METH_VARARGS, "Write in fifo with given id"},
	{"fifoRead", fifoRead, METH_VARARGS, "Read from fifo with given id"},
	{"directRead", directRead, METH_VARARGS, "Read from with given offset"},
	{"directWrite", directWrite, METH_VARARGS, "Write to given offset"},
	{"fifoClose", fifoClose, METH_VARARGS, "Close fifo with given id"},
	{NULL, NULL, 0, NULL}
};

PyMODINIT_FUNC

initlogipi(void)
{
	(void) Py_InitModule("logipi", logipiMethods);
	
}
