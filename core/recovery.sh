#!/bin/bash
#sudo su
echo "*-*-*-- MINERSTAT OS RECOVERY --*-*-*"
echo "*-*-*-- WAITING FOR CONNECTION --*-*-*"
echo "Connecting to recovery server..."
while ! ping labs.minerstat.farm -w 1 | grep "0%"; do
  sleep 1
done
echo "Connecting to API ..."
while ! ping api.minerstat.com -w 1 | grep "0%"; do
  sleep 1
done
sudo killall node
sudo screen -S minerstat-console -X quit
sudo screen -S listener -X quit
sudo rm -rf /home/minerstat/minerstat-os
cd /home/minerstat
ls
git clone http://labs.minerstat.farm/repo/minerstat-os.git/
chmod 777 minerstat-os
cd /home/minerstat/minerstat-os
sudo chmod -R 777 *
sudo npm config set registry http://registry.npmjs.org/

echo "Fetching IP.."
IP=$(timeout 10 wget -O - -q https://status.minerstat.com/loc.php)
echo "IP Attempt to find closest server: $IP"

if [[ "$IP" = "CN" ]] || [[ "$IP" = "HK" ]] || [[ "$IP" = "TW" ]]; then
  echo "Proxy NPM server selected"
  sudo npm config set registry http://r.cnpmjs.org
else
  echo "Global NPM server selected"
  sudo npm config set registry http://registry.npmjs.org
fi

sudo npm update
sudo npm install
sudo chmod -R 777 *
echo "Copy config from MSOS (NTFS) Partition"
cp /media/storage/config.js /home/minerstat/minerstat-os
echo ""
cat config.js
echo ""
echo ""
echo "Recovery is done!"
sudo echo "boot" > /home/minerstat/minerstat-os/bin/random.txt
screen -S listener -X quit # kill running process
screen -A -m -d -S listener sudo sh /home/minerstat/minerstat-os/core/init.sh
echo "MUPDATE"
sudo bash /home/minerstat/minerstat-os/git.sh
echo "You can start mining again with: mstart"
echo ""
echo "*-*-*-- MINERSTAT.COM--*-*-*"
