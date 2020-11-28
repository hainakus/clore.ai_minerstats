#!/bin/bash

sudo echo 1 > /proc/sys/kernel/sysrq #enable

# sync, unmount, reboot
sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk

# attempt to reboot rig with watchdog
sudo /home/minerstat/minerstat-os/bin/watchdog-reboot.sh nosync

sudo echo u > /proc/sysrq-trigger #(*U*mount) Umounts all mounted partitions
sudo echo b > /proc/sysrq-trigger # (re*B*oot) Reboots the system
