#!/bin/bash

SYSLOAD=$(sudo cat /proc/loadavg | awk '{print $1}' | cut -f1 -d".")
sudo echo 1 > /proc/sys/kernel/sysrq #enable sysrq

# kill watchdog pings
sudo killall watchdog >/dev/null 2>&1

# sync, unmount, reboot
RAMLOG=""
RAMLOG=$(timeout 5 cat /dev/shm/miner.log | tac | head --lines 10 | tac)
sudo echo s > /proc/sysrq-trigger #(*S*nc) Sync all cached disk operations to disk
sudo echo u > /proc/sysrq-trigger #(*U*mount) Umounts all mounted partitions

# attempt

TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"

function reboots () {
  RAMLOG="$RAMLOG - System reboot"
  timeout 4 sudo curl --insecure --connect-timeout 2 --max-time 3 --retry 0 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "mineLog=$RAMLOG" "https://api.minerstat.com:2053/v2/set_node_config_os2.php"
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
  RAMLOG="$RAMLOG - System shutdown"
  timeout 4 sudo curl --insecure --connect-timeout 2 --max-time 3 --retry 0 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "mineLog=$RAMLOG" "https://api.minerstat.com:2053/v2/set_node_config_os2.php"
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
  RAMLOG="$RAMLOG - System PowerCycle"
  timeout 4 sudo curl --insecure --connect-timeout 2 --max-time 3 --retry 0 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "mineLog=$RAMLOG" "https://api.minerstat.com:2053/v2/set_node_config_os2.php"
  # Check it is supported, if not use normal reboot
  if [ -f "/sys/class/rtc/rtc0/wakealarm" ]; then
    sudo su -c "echo 0 > /sys/class/rtc/rtc0/wakealarm"
    sudo su -c "echo +30 > /sys/class/rtc/rtc0/wakealarm"
    sdown
  else
    # Reboot because wakealarm not supported
    reboots
  fi
  # If not $1 powercycle then probably just normal reboot so processing trough the script
  exit 1
fi

reboots
