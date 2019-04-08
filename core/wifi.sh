#!/bin/bash

INTERFACE="$(ls /sys/class/net)"
DEVICE=""
SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g')
PASSWD=$(cat /media/storage/network.txt | grep 'WIFIPASS="' | sed 's/WIFIPASS="//g' | sed 's/"//g')

echo ""
echo "*** Connecting to Wireless Network ***"
echo ""

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


  CONNECT=$(nmcli device wifi connect $SSID password $PASSWD)

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
  sudo resolvconf -u
  sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
  sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
  # For msos versions what have local DNS cache
  sudo su -c 'echo "nameserver 127.0.0.1" >> /etc/resolv.conf'

  echo ""
  TEST="$(ping google.com -w 1 | grep '1 packets transmitted')"

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
