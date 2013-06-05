#!/bin/sh

gpsd -n /dev/ttyUSB0
python avc_navigation.py
