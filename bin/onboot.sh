#!/bin/bash

file=/home/minerstat/minerstat-os/bin/random.txt
if [ -e "$file" ]; then
  sleep 1;
  if ! screen -list | grep -q "dummy"; then
    echo "Moving MSOS config.js to / (LINUX)"
    sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"
    screen -A -m -d -S boot_process /home/minerstat/minerstat-os/bin/work.sh
  fi
else
    screen -A -m -d -S boot_process /home/minerstat/minerstat-os/bin/boot.sh
fi
