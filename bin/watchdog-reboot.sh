#!/bin/bash

if [[ "$1" != "nosync" ]]; then
  sudo echo 1 > /proc/sys/kernel/sysrq #enable
  sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk
fi

echo ""
echo "Sending reboot signal.."
echo ""

# attempt to reboot rig with watchdog
sudo su -c "printf '\xFF\x55' >/dev/ttyUSB*"
sudo su -c "printf '\xFF\x55' >/dev/hidraw*"
sudo su -c "echo -n '~T1' >/dev/ttyACM*"
