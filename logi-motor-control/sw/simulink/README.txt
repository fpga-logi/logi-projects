MATLAB r2014b Simulink Models using BeagleBoneBlack support package for Embedded Coder

Uses motor control bitstream in hw directory.

Tested with PmodHB5 modules plugged into top row of PMOD1 and PMOD2 ports, and 
two Digilent geared DC motors (1:53 reduction)

Included S-Functions built for MS Windows 64-bits

Runs on standard logibone image referenced in logibone quick start guide, but 
you must first disable password authentication for ubuntu user in
sudoers file. Run sudo visudo and add the following on last line: 

ubuntu ALL = NOPASSWD: ALL 

TODO: 
-Models currently limited to 10Hz max
-Combine multiple logibone reads and write into a single one for performance?
-Use logibone library?
-Load bitstream in block initialization?
-Bitstream load conditional on checksum register perhaps?
-Pass certain data as block parameters instead of input signals?
-Build for win32?