#!/bin/bash
echo ""
echo "*** Auto DHCP Configuration ***"
echo ""

INTERFACE="$(sudo cat /proc/net/dev | tail -n1 | awk -F '\\:' '{print $1}')"

echo "Configuring LAN DHCP for: "$INTERFACE
echo ""

echo -n > /etc/network/interfaces
echo auto $INTERFACE  >> /etc/network/interfaces
echo iface $INTERFACE inet dhcp  >> /etc/network/interfaces
#echo dns-nameservers 1.1.1.1 >> /etc/network/interfaces
/etc/init.d/networking restart

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
