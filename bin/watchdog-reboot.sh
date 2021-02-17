#!/bin/bash

if [[ "$1" != "nosync" ]]; then
  sudo echo 1 > /proc/sys/kernel/sysrq #enable
  sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk
fi

echo ""
echo "Sending reboot signal"
echo -e "  [i] If the computer not rebooting after this command watchdog not supported or not properly installed into the motherboard reset slot \r"
echo -e "  [i] Hint: Make sure no keyboard / mouse attached to the motherboard. Those can fail the watchdog script. \r"
echo ""

# attempt to reboot rig with watchdog
sudo su -c "printf '\xFF\x55' >/dev/ttyUSB*"
sudo su -c "printf '\xFF\x55' >/dev/hidraw*"
sudo su -c "echo -n '~T1' >/dev/ttyACM*"

# Is octo or minerdude board ?
if [[ -f "/dev/shm/octo.pid" ]]; then
  timeout 5 sudo /home/minerstat/minerstat-os/bin/fan_controller_cli -w 0 -v 0
  sudo /home/minerstat/minerstat-os/core/octoctrl --reboot
fi
# watchdog in ua
P5=$(lsusb | grep "16c0:03e8")
if [ ! -z "$P5" ]; then
  timeout 3 sudo /home/minerstat/minerstat-os/bin/watchdoginua $TIMEOUT testreset
fi

# echo lsusb
echo "Listing detected USB devices"
echo -e "  [i] Check below your USB recognised or not \r"

sudo lsusb
