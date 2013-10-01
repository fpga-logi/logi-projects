need to compile read/write tools on beaglebone with the following commands (to lazy to write the Makefile):
gcc -o write_wishbone write_wishbone.c
gcc -o read_wishbone read_wishbone.c

read tool usage :

sudo read_wishbone <hex address>
example : sudo read_wishbone 0x0004

write tool usage:

sudo write_wishbone <hex address> <hex value>
example : sudo write_wishbone 0x0004 0xBEEF 

address of peripherals are in the MEMORY_LAYOUT.TXT file
