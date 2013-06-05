#!/bin/sh

modprobe spi_bcm2708
modprobe i2c_dev
logi_loader avc_platform.bit
gpsd -n /dev/ttyUSB0
python avc_navigation.py
