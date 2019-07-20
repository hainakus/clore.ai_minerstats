#!/bin/bash

INTERFACE="$(ls /sys/class/net)"
DEVICE=""
SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g')
PASSWD=$(cat /media/storage/network.txt | grep 'WIFIPASS="' | sed 's/WIFIPASS="//g' | sed 's/"//g')

echo ""
echo "*** Connecting to Wireless Network ***"
echo ""

sudo su -c "rm /etc/netplan/minerstat.yaml"

for dev in $INTERFACE; do
  if [ -d "/sys/class/net/$dev/wireless" ]; then DEVICE=$dev; fi;
done

if echo "$DEVICE" | grep "w" ;then

  echo "Configuring Wifi Connection for: "$DEVICE
  echo ""
  echo ""
  echo "SSID: $SSID"

  nmcli d wifi rescan
  nmcli d wifi list

  sleep 1

  nmcli device wifi connect "$SSID" password "$PASSWD" > /tmp/wifi.log

  CONNECT=$(cat /tmp/wifi.log)
  echo
  echo $CONNECT
  echo

  echo "If error happens during connection. Press CTRL + A + D"
  echo "After you will be able to enter commands to the terminal"
  echo 
  echo "To connect manually enter: mwifi SSID PASSWORD"
  echo

  if echo "$CONNECT" | grep "failed" ;then
    echo ""
    echo "Adapter activation failed";
    echo "You should replug Wifi adapter to your system"
    sleep 10
    cd /home/minerstat/minerstat-os/core
    sudo sh wifi.sh
    echo ""
    exit
  else

    echo $CONNECT

  fi

  # CloudFlare DNS
  sudo su -c 'echo "" > /etc/resolv.conf'
  #sudo resolvconf -u
  sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
  # For msos versions what have local DNS cache
  sudo su -c 'echo "nameserver 127.0.0.1" >> /etc/resolv.conf'
  # IPV6
  sudo su -c 'echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf'
  sudo su -c 'echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf'
  # systemd resolve casusing problems with 127.0.0.53
  sudo su -c 'echo "nameserver 1.1.1.1" > /run/resolvconf/interface/systemd-resolved'
  sudo su -c 'echo "nameserver 1.0.0.1" >> /run/resolvconf/interface/systemd-resolved'
  sudo su -c 'echo "nameserver 1.1.1.1" > /run/systemd/resolve/stub-resolv.conf'
  sudo su -c 'echo "nameserver 1.0.0.1" >> /run/systemd/resolve/stub-resolv.conf'
  sudo su -c 'echo options edns0 >> /run/systemd/resolve/stub-resolv.conf'

  echo ""
  TEST="$(ping api.minerstat.com. -w 1 | grep '1 packets transmitted')"

  if echo "$TEST" | grep "0%" ;then
    echo ""
    echo "Success! You have active internet connection."
  else
    echo ""
    echo "Oh! Something went wrong, you are not connected to the internet."
  fi

else
  echo "No supported wifi adapter found";
fi
