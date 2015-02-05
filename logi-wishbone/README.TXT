Virtual Component Project *************************************************************************
* DOCUMENTATION: http://valentfx.com/wiki/index.php?title=LOGI_-_Wishbone_-_Project
* DESCRIPTION  **************
The wishbone bus is a open source parallel bus generally used internally in FPGAs or ASICs to interconnect a master or multi-master with many slave peripherals.  The wishbone bus was chosen as an interconnect for the LOGI FPGAs as there are a multitude of available cores available that can be directly and easily implemented within the all the majority of the LOGI project architectures.  Open cores and many other online resources provide source for peripheral implementation that are compatible with wishbone. 
* INSTRUCTIONS *************
Generate Programming File using Xilinx ISE open: File | New Project | logi-virtual-components/hw/logipi/ise/logipi_wishbone.xise
startx
python2 test_wishbone.py
* TROUBLESHOOTING **********

* SUGGESTIONS **************
Try the C language examples in sw folder
*************************************************************************************
