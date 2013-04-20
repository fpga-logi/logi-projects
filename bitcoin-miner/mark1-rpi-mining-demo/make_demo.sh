#!/bin/sh
cd SPI-Py-master
python setup.py build
python setup.py install
cd ../
UBUNTU='cat /etc/issue | grep Ubuntu';
if [ -n "$UBUNTU" ]; then
 apt-get install python-json python-mmap
else
 opkg install python-json python-mmap
fi
echo "wait for the following script to end"
echo "result should be : nonce :7a33330e "
echo "1) Create an account on mining pool (tested on btcguild and bitlc)"
echo "2) Configure a worker on the pool website"
echo "3) Fill config.py with your worker configuration"
echo "4) Launch python mark1_rpi_miner.py and wait to get rich ..."
echo "INFO: the hashrate (~1.8MHash/s) is intentionnaly limited to prevent the FPGA from overheating."
echo "Because of the low hashrate (compared to bigger FPGA or ASIC), expect to wait some time before getting a valid share ..."

