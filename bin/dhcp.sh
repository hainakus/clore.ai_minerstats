#!/bin/bash
echo ""
echo "*** Auto DHCP Configuration ***"
echo ""

INTERFACE="$(sudo cat /proc/net/dev | tail -n1 | awk -F '\\:' '{print $1}')"

echo "Configuring LAN DHCP for: "$INTERFACE
echo ""

sudo su -c "echo -n > /etc/network/interfaces"
sudo su -c "echo allow-hotplug $INTERFACE  >> /etc/network/interfaces"
sudo su -c "echo iface $INTERFACE inet dhcp  >> /etc/network/interfaces"

# CloudFlare DNS
sudo su -c 'echo "" > /etc/resolv.conf'
sudo resolvconf -u
sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf'
sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

sudo su -c '/etc/init.d/networking restart'
sudo su -c "systemctl restart systemd-networkd"
sudo ifdown $INTERFACE
sudo ifup $INTERFACE

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
