#!/bin/bash
echo "*-*-*-- MINERSTAT OS RECOVERY --*-*-*"
echo "*-*-*-- WAITING FOR CONNECTION --*-*-*"
while ! ping minerstat.farm -w 1 | grep "0%"; do
  sleep 1
done
sudo killall node
sudo screen -S minerstat-console -X quit
sudo screen -S listener -X quit
sudo rm -rf /home/minerstat/minerstat-os
cd /home/minerstat
ls
git clone https://github.com/minerstat/minerstat-os
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
