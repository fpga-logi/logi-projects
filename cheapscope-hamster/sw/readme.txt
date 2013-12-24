Cheapscope Setup:

- install libncurses:	sudo apt-get install libncurses5-dev 
- build cheapscope: 	gcc -o cheapscope cheapscope.c -lncurses
- ensure that rpi ttyAMA0 is not being used by system (used by default): 

- Easy utility to all user access to serial port 
- install using: 
sudo wget https://raw.github.com/lurch/rpi-serial-console/master/rpi-serial-console -O /usr/bin/rpi-serial-console && sudo chmod +x /usr/bin/rpi-serial-console
- if already installed: 
cp rpi-serial-console /usr/bin/rpi-serial-console && sudo chmod +x /usr/bin/rpi-serial-console

- Check the status:  	rpi-serial-console status
- if enabled user must disable the ttyama0 port(make available for user access): sudo rpi-serial-console disable
- reboot
- run the cheapscope: 	./cheapscope /dev/ttyAMA0

