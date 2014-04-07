OVERVIEW ********************************************************************************************
need to compile read/write tools on beaglebone with the following commands (too lazy to write the Makefile):
gcc -o write_wishbone write_wishbone.c
gcc -o read_wishbone read_wishbone.c

read tool usage :

sudo read_wishbone <hex address>
example : sudo read_wishbone 0x0004

write tool usage:

sudo write_wishbone <hex address> <hex value>
example : sudo write_wishbone 0x0004 0xBEEF 


WISHBONE ADDRESSES ********************************************************************************
address	   |	name	   |	note	|
0x0000	     register_0        read :0xDEAD
0x0002	     register_1	       read : 0xBEEF 
0x0004	     register_3	       read/write register
0x0006	     register_4	       write pmod2/read pmod1 and switches
0x0010	     pwm_divider       system_clock divider for pwm
0x0012	     pwm_period	       pwm signal period
0x0014	     pwm0_high	       high time for pwm0 (unconnected)
0x0016	     pwm1_high	       high time for pwm1 connected to LED0
0x0018	     pwm2_hight	       high time for pwm2 connected to LED1


WISHBONE WALK-THROUGH EXAMPLES **********************************************************************

SETUP TO RUN THE EXAMPLE
1) setup the BBB device tree
	ubuntu@arm:~$ sudo ./setup_device-tree.sh 
2) load the fpga bit file
	ubuntu@arm:~$ sudo logi_loader bitfiles/logibone_wishbone.bit 
3) go to the wishbone directory to experiment with the GPMC/wishbone BBB/FPGA interface
	ubuntu@arm:~$ cd wishbone/

READ REGISTER ON THE FPGA
1) Read register 0x0000 on the FPGA
	ubuntu@arm:~/wishbone$ sudo ./read_wishbone 0x0000
	should return 0xdead
2) Read register 0x0001 on the FPGA
	ubuntu@arm:~/wishbone$ sudo ./read_wishbone 0x0001
	should return 0xbeef

WRITE AND READ AN UNINITIALIZED REGISTER ON THE FPGA
1) read the uninitialized register_3 (0x0004)
	ubuntu@arm:~/wishbone$ sudo ./read_wishbone 0x004
	should return: 0x0 
2) write a value of 0x1234 to register_3  
	ubuntu@arm:~/wishbone$ sudo ./write_wishbone 0x0004 0x1234
	should output: Writing 0x1234 @ 0x4 
3) read back the contents stored in register_3
	ubuntu@arm:~/wishbone$ sudo ./read_wishbone 0x004
	should return: 0x1234 


SETUP LED PWM REGISTER TO CONTROL THE INTENSITY OF THE LEDS
1) Load the clock divider register with 0x0004
	ubuntu@arm:~/wishbone$ sudo ./write_wishbone 0x0010 0x0004
	should return: Writing 0x10 @ 0x4 

2) Load the period register with 0x0800
	ubuntu@arm:~/wishbone$ sudo ./write_wishbone 0x0012 0x0800
	should return: Writing 0x800 @ 0x12 
3) Load the LED1 register with the duty cycle value
	ubuntu@arm:~/wishbone$ sudo ./write_wishbone 0x0016 0x0080
	should return: Writing 0x80 @ 0x16 
	you should see LED1 light up with the brightness relative to pwm_period/pwm_duty(high time)
4) Load the LED2 register with the duty cycle value
	ubuntu@arm:~/wishbone$ sudo ./write_wishbone 0x0018 0x0080
	should return: Writing 0x80 @ 0x16 
	you should see LED2 light up with the brightness relative to pwm_period/pwm_duty(high time)
5) Experiment with setting the brightness of the LEDS by writing the the pwm_high registers

