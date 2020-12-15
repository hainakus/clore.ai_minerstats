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

# echo lsusb
echo "Listing detected USB devices"
echo -e "  [i] Check below your USB recognised or not \r"

sudo lsusb
