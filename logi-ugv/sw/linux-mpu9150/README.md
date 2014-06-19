# linux-mpu9150

An implementation of 9-axis data fusion on Linux using the [InvenSense MPU-9150 IMU][1]

The linux-mpu9150 code uses the InvenSense Embedded Motion Driver v5.1.1 SDK
to obtain fused 6-axis quaternion data from the MPU-9150 DMP. The quaternion
data is then further corrected in the linux-mpu0150 code with magnetometer 
data collected from the IMU.

Because it is primarily intended for use on small-board ARM computers, the 
linux-mpu9150 code uses 32-bit floats rather then doubles for all floating 
point operations.

Testing has been done with [Raspberry Pi][2] and [Gumstix Overo and Duovero][3] systems.
The code should work fine with other small board systems like the [BeagleBones][4].

We have our own boards incorporating the MPU9150s, but we also tested with the
[Sparkfun MPU9150 Breakout Boards][5]

[1]: http://www.invensense.com/mems/gyro/nineaxis.html     "InvenSense"
[2]: http://www.raspberrypi.org/                           "Raspberry Pi"
[3]: https://www.gumstix.com/                              "Gumstix"
[4]: http://beagleboard.org/                               "Beagleboard"
[5]: https://www.sparkfun.com/products/11486               "Sparkfun"


# Fetch

Use git to fetch the linux-mpu9150 project. You may have to install <code>git</code> on your
system first.

For RPi users running Raspbian, use this command

        sudo apt-get install git

Then to clone the repository assuming you have an Internet connection

        git clone https://github.com/Pansenti/linux-mpu9150.git


# Build

The linux-mpu9150 code is written in C. There is a make file called <code>Makefile-native</code>
for use when building directly on the system.

There is also a <code>Makefile-cross</code> makefile for use when using Yocto Project built
tools and cross-building linux-mpu9150 on a workstation. This is more for Gumstix
and Beagle users.

A recommendation is to create a soft-link to the make file you want to use.

        root@duovero:~$ cd linux-mpu9150
        root@duovero:~/linux-mpu9150$ ln -s Makefile-native Makefile


After that you can just type <code>make</code> to build the code.

        root@duovero:~/linux-mpu9150$ make
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c eMPL/inv_mpu.c
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c eMPL/inv_mpu_dmp_motion_driver.c
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c glue/linux_glue.c
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c mpu9150/mpu9150.c
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c mpu9150/quaternion.c
        gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c mpu9150/vector3d.c
        gcc -Wall -I eMPL -I glue -I mpu9150 -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c imu.c
        gcc -Wall inv_mpu.o inv_mpu_dmp_motion_driver.o linux_glue.o mpu9150.o quaternion.o vector3d.o imu.o -lm -o imu
        gcc -Wall -I eMPL -I glue -I mpu9150 -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c imucal.c
        gcc -Wall inv_mpu.o inv_mpu_dmp_motion_driver.o linux_glue.o mpu9150.o quaternion.o vector3d.o imucal.o -lm -o imucal


The result is two executables called <code>imu</code> and <code>imucal</code>.

For those using <code>Makefile-cross</code>, you will need to export an environment variable
called <code>OETMP</code> that points to your OE temp directory (TMPDIR in build/conf/local.conf).

For example:

        scott@hex:~/linux-mpu9150$ export OETMP=/oe1
        scott@hex:~/linux-mpu9150$ ln -s Makefile-cross Makefile
        scott@hex:~/linux-mpu9150$ make
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c eMPL/inv_mpu.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c eMPL/inv_mpu_dmp_motion_driver.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c glue/linux_glue.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -I eMPL -I glue -c mpu9150/mpu9150.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c mpu9150/quaternion.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c mpu9150/vector3d.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -I eMPL -I glue -I mpu9150 -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c imu.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall inv_mpu.o inv_mpu_dmp_motion_driver.o linux_glue.o mpu9150.o quaternion.o vector3d.o imu.o -lm -o imu
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall -I eMPL -I glue -I mpu9150 -DEMPL_TARGET_LINUX -DMPU9150 -DAK8975_SECONDARY -c imucal.c
        /oe1/sysroots/`uname -m`-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc -Wall inv_mpu.o inv_mpu_dmp_motion_driver.o linux_glue.o mpu9150.o quaternion.o vector3d.o imucal.o -lm -o imucal


If you are using a <strong>hard-floating point</strong> built cross-toolchain, then comment/uncomment 
the appropriate <code>CC</code> and <code>CFLAGS</code> lines in <code>Makefile-cross</code>.

### local_defaults.h

You can modify some default parameter settings in <code>local_defaults.h</code> to avoid
having to pass command line switches to the applications every run. 

After modifying <code>local_defaults.h</code>, you will have to run <code>make</code> again. 

The defaults in  <code>local_defaults.h</code> are for the RPi.


# Enable i2c

### Raspberry Pi

The RPi Raspbian distribution does not load the I2C kernel drivers by default.

You can check with this command:

        pi@raspberrypi:~/linux-mpu9150$ dmesg | grep i2c
        [   15.683106] i2c /dev entries driver
        [   15.767128] bcm2708_i2c bcm2708_i2c.0: BSC0 Controller at 0x20205000 (irq 79) (baudrate 100k)
        [   15.785938] bcm2708_i2c bcm2708_i2c.1: BSC1 Controller at 0x20804000 (irq 79) (baudrate 100k)

If you don't see output like the above, edit <code>/etc/modules</code> and add these lines

        i2c-bcm2708
        i2c-dev

The I2C device on the RPi P1 header will be <code>/dev/i2c-1</code>.


### Gumstix

The I2C kernel driver for the Gumstix boards is usually loaded by default.

The I2C device on the Gumstix Overo expansion header is <code>/dev/i2c-3</code>.

On the Duovero the device it is <code>/dev/i2c-2</code>.


### Any System

The permissions on the /dev/i2c-X device are usually set so that only the
root user has permissions.

To avoid having to use sudo to run the code a udev rule can be used to
change the permissions on startup.

Create a file:

        /etc/udev/rules.d/90-i2c.rules

and add the line:

        KERNEL=="i2c-[0-3]",MODE="0666"


Reboot to make sure everything is set correctly.

If you are running as root you don't need the udev rule.


# Calibration

The IMU gyros have a built in calibration mechanism, but the accelerometers
and the magnetometer require manual calibration.

Calibration, particularly magnetometer calibrations, is a complicated topic.
We've provided a simple utility application called <code>imucal</code> that can get you
started.

        pi@raspberrypi:~/linux-mpu9150$ ./imucal -h
         
        Usage: ./imucal <-a | -m> [options]
          -b <i2c-bus>          The I2C bus number where the IMU is. The default is 1 for /dev/i2c-1.
          -s <sample-rate>      The IMU sample rate in Hz. Range 2-50, default 10.
          -a                    Accelerometer calibration
          -m                    Magnetometer calibration
                                Accel and mag modes are mutually exclusive, but one must be chosen.
          -f <cal-file>         Where to save the calibration file. Default ./<mode>cal.txt
          -h                    Show this help
        
        Example: ./imucal -b3 -s20 -a

You'll need to run this utility twice, once for the accelerometers and
again for the magnetometer.

Here is how to generate accelerometer calibration data on an RPi. 
The default bus and sample rate are used.

        pi@raspberrypi:~/linux-mpu9150$ ./imucal -a
        
        Initializing IMU .......... done
        
        
        Entering read loop (ctrl-c to exit)
        
        X -16368|16858|16858    Y -16722|-2490|16644    Z -17362|-562|17524             ^C


The numbers shown are min|current|max for each of the axes.

What you want to do is slowly move the RPi/imu through all orientations in
three dimensions. Slow is the the key. We are trying to measure gravity only
and sudden movements will induce unwanted accelerations.

The values will update whenever there is a change in one of the min/max
values, so when you see no more changes you can enter ctrl-c to exit
the program.

When it finishes, the program will create an <code>accelcal.txt</code> file
recording the min/max values.

        pi@raspberrypi:~/linux-mpu9150$ cat accelcal.txt 
        -16368
        16858
        -16722
        16644
        -17362
        17524


Do the same thing for the magnetometers running <code>imucal</code> with the -m switch.

        pi@raspberrypi:~/linux-mpu9150$ ./imucal -m
        
        Initializing IMU .......... done
        
        
        Entering read loop (ctrl-c to exit)
        
        X -179|-54|121    Y -154|199|199    Z -331|-124|15             ^C


Again move the device through different orientations in all three dimensions
until you stop seeing changes. You can move faster during this calibration
since we aren't looking at accelerations.

After ending the program with ctrl-c, a calibration file called <code>magcal.txt</code>
will be written.

        pi@raspberrypi:~/linux-mpu9150$ cat magcal.txt 
        -179
        121
        -154
        199
        -331
        15


If these two files, <code>accelcal.txt</code> and <code>magcal.txt</code>, are left in the
same directory as the <code>imu</code> program, they will be used by default.


# Run

The <code>imu</code> application is a small example to get started using 
<code>linux-mpu9150</code> code.

        pi@raspberrypi ~/linux-mpu9150 $ ./imu -h

        Usage: ./imu [options]
          -b <i2c-bus>          The I2C bus number where the IMU is. The default is 1 to use /dev/i2c-1.
          -s <sample-rate>      The IMU sample rate in Hz. Range 2-50, default 10.
          -y <yaw-mix-factor>   Effect of mag yaw on fused yaw data.
                                0 = gyro only
                                1 = mag only
                                > 1 scaled mag adjustment of gyro data
                                The default is 4.
          -a <accelcal file>    Path to accelerometer calibration file. Default is ./accelcal.txt
          -m <magcal file>      Path to mag calibration file. Default is ./magcal.txt
          -v                    Verbose messages
          -h                    Show this help

        Example: ./imu -b3 -s20 -y10


The defaults will work for an RPi with the two calibration files picked
up automatically.


        pi@raspberrypi ~/linux-mpu9150 $ ./imu

        Initializing IMU .......... done


        Entering read loop (ctrl-c to exit)

         X: -2 Y: -62 Z: -4        ^C


The default output of the <code>imu</code> program are the fused Euler angles.
Other outputs are available such as the fused quaternion and the
raw gyro, accel and mag values. See the source code.

Keep in mind <code>imu</code> is just a demo app not optimized for any particular
use. The idea is that you'll write your own program to replace <code>imu</code>.

All of the functions in the Invensense SDK under the <code>eMPL</code> directory
are available. See <code>mpu9150/mpu9150.c</code> for some examples.

