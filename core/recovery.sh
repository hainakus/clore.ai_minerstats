#!/bin/bash
echo "*-*-*-- MINERSTAT OS RECOVERY --*-*-*"
sudo killall node
sudo screen -S minerstat-console -X quit
sudo screen -S listener -X quit
sudo rm -rf /home/minerstat/minerstat-os
cd /home/minerstat
ls
git clone http://github.com/minerstat/minerstat-os
cd /home/minerstat/minerstat-os
sudo npm install
chmod -R 777 *
echo "Copy config from MSOS (NTFS) Partition"
cp /media/storage/config.js /home/minerstat/minerstat-os
echo ""
cat config.js
echo ""
echo ""
echo "Recovery is done!"
echo "Ctrl + C to abort reboot."
sleep 3
echo "Rebooting ..."
sudo reboot -f
echo ""
echo "*-*-*-- MINERSTAT.COM--*-*-*"
