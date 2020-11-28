#!/bin/bash

echo ""
echo "Sending reboot signal.."
echo ""

# attempt to reboot rig with watchdog
sudo su -c "printf '\xFF\x55' >/dev/ttyUSB*"
sudo su -c "printf '\xFF\x55' >/dev/hidraw*"
sudo su -c "echo -n '~T1' >/dev/ttyACM*"
