#!/usr/bin/bash

#echo "Freeing up RAM. Please wait..";
#sync; sudo su -c "echo 1 > /proc/sys/vm/drop_caches"
# can't create socket: Permission denied
sudo rm -r /tmp/tmux-*
sudo su -c "sudo screen -X -S minew quit"
sudo su -c "sudo screen -X -S fakescreen quit"
sudo su minerstat -c "screen -X -S fakescreen quit"
#sudo su minerstat -c 'screen -X -S minerstat-console quit'

screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh

node /home/minerstat/minerstat-os/validate.js > /dev/shm/validate_node.txt 2>&1
READBACK=$(cat /dev/shm/validate_node.txt)

if [[ $READBACK == *"unexpected"* ]] || [[ $READBACK == *"Unexpected"* ]]; then
  echo ""
  echo "!!!!!!!!!"
  echo "Invalid config.js file. Manual action required!"
  echo "Type: mworker accesskey workername"
  echo "Replace accesskey/workername with your details. After you can try mstart again."
  echo "!!!!!!!!!"
  echo ""
elif [[ $READBACK == *"Cannot"* ]] || [[ $READBACK == *"color"* ]]; then
  echo ""
  echo "!!!!!!!!!"
  echo "Some important files missing."
  echo "Type: netrecovery"
  echo "After netrecovery command OS attempt to restore itself to original state. After you can try mstart again."
  echo "!!!!!!!!!"
  echo ""
else
  bash launcher.sh
fi
