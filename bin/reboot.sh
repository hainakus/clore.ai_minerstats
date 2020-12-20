#!/bin/bash

SYSLOAD=$(sudo cat /proc/loadavg | awk '{print $1}' | cut -f1 -d".")
sudo echo 1 > /proc/sys/kernel/sysrq #enable sysrq

# kill watchdog pings
sudo killall watchdog >/dev/null 2>&1

# sync, unmount, reboot
sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk
sudo echo u > /proc/sysrq-trigger #(*U*mount) Umounts all mounted partitions

function reboot () {
  # Is octo or minerdude board ?
  if [[ -f "/dev/shm/octo.pid" ]]; then
    sudo /home/minerstat/minerstat-os/core/octoctrl --reboot
  fi
  # attempt to reboot rig with watchdog
  sudo /home/minerstat/minerstat-os/bin/watchdog-reboot.sh nosync
  # if upper failes reboot normally
  sudo echo b > /proc/sysrq-trigger # (re*B*oot) Reboots the system
}

function sdown () {
  if [[ -f "/dev/shm/octo.pid" ]]; then
    sudo /home/minerstat/minerstat-os/core/octoctrl --shutdown
  fi
  if [[ "$SYSLOAD" -gt 10 ]]; then
    # Shutdown forced
    sudo echo o > /proc/sysrq-trigger # (shutd*O*wn) Shutdown the system
    sleep 2
    sudo poweroff # just safety failover
  else
    # Shutdown
    sudo poweroff
  fi
}

if [[ "$1" = "shutdown" ]]; then
  sdown
  exit 1
fi

if [[ "$1" = "safeshutdown" ]]; then
  sudo poweroff
  exit 1
fi

if [[ "$1" = "powercycle" ]]; then
  # Check it is supported, if not use normal reboot
  if [ -f "/sys/class/rtc/rtc0/wakealarm" ]; then
    sudo su -c "echo 0 > /sys/class/rtc/rtc0/wakealarm"
    sudo su -c "echo +30 > /sys/class/rtc/rtc0/wakealarm"
    sdown
  else
    # Reboot because wakealarm not supported
    reboot
  fi
  # If not $1 powercycle then probably just normal reboot so processing trough the script
  exit 1
fi

reboot
