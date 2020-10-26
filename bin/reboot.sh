#!/bin/bash

sudo echo 1 > /proc/sys/kernel/sysrq #enable

# attempt to reboot rig with watchdog
sudo su -c "printf '\xFF\x55' >/dev/ttyUSB*"
sudo su -c "printf '\xFF\x55' >/dev/hidraw*"
sudo su -c "echo -n '~T1' >/dev/ttyACM*"

# sync, unmount, reboot
sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk
sudo echo u > /proc/sysrq-trigger #(*U*mount) Umounts all mounted partitions
sudo echo b > /proc/sysrq-trigger # (re*B*oot) Reboots the system
