#!/bin/bash
echo ""
echo "*** STATIC LAN Configuration ***"
echo ""

INTERFACE="$(sudo cat /proc/net/dev | tail -n1 | awk -F '\\:' '{print $1}')"

# READ FROM network.txt
ADDRESS=$(cat /media/storage/network.txt | grep 'IPADDRESS="' | sed 's/IPADDRESS="//g' | sed 's/"//g')
NETMASK=$(cat /media/storage/network.txt | grep 'NETMASK="' | sed 's/NETMASK="//g' | sed 's/"//g')
GATEWAY=$(cat /media/storage/network.txt | grep 'GATEWAY="' | sed 's/GATEWAY="//g' | sed 's/"//g')

echo "Configuring LAN for: "$INTERFACE
echo ""

echo -n > /etc/network/interfaces
echo auto $INTERFACE  >> /etc/network/interfaces
echo iface $INTERFACE inet static  >> /etc/network/interfaces
echo address $ADDRESS >> /etc/network/interfaces
echo netmask $NETMASK >> /etc/network/interfaces
echo gateway $GATEWAY >> /etc/network/interfaces
echo dns-nameservers 1.1.1.1 >> /etc/network/interfaces

# CloudFlare DNS
sudo echo "" > /etc/resolv.conf
sudo echo "nameserver 1.1.1.1" >> /etc/resolv.conf
sudo echo "nameserver 1.0.0.1" >> /etc/resolv.conf
sudo echo "nameserver 8.8.8.8" >> /etc/resolv.conf
sudo echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sudo resolvconf -u

/etc/init.d/networking restart
sudo su -c "systemctl restart systemd-networkd"

echo ""
TEST="$(ping google.com -w 1 | grep '1 packets transmitted')"

if echo "$TEST" | grep "0%" ;then
    echo ""
    echo "Success! You have active internet connection."
else
    echo ""
    echo "Oh! Something went wrong, you are not connected to the internet."
fi

echo ""
echo "*** https://minerstat.com ***"
echo ""
