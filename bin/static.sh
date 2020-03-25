#!/bin/bash
echo ""
echo "*** STATIC LAN Configuration ***"
echo ""

sudo su -c "rm /etc/netplan/minerstat.yaml"

INTERFACE="$(sudo cat /proc/net/dev | grep -vE "lo|docker0" | tail -n1 | awk -F '\\:' '{print $1}' | xargs)"

# READ FROM network.txt
ADDRESS=$(cat /media/storage/network.txt | grep 'IPADDRESS="' | sed 's/IPADDRESS="//g' | sed 's/"//g')
NETMASK=$(cat /media/storage/network.txt | grep 'NETMASK="' | sed 's/NETMASK="//g' | sed 's/"//g')
GATEWAY=$(cat /media/storage/network.txt | grep 'GATEWAY="' | sed 's/GATEWAY="//g' | sed 's/"//g')

echo "Configuring LAN for: "$INTERFACE
echo ""

sudo su -c "echo -n > /etc/network/interfaces" 2>/dev/null
sudo su -c "echo auto $INTERFACE  >> /etc/network/interfaces" 2>/dev/null
sudo su -c "echo iface $INTERFACE inet static  >> /etc/network/interfaces" 2>/dev/null
sudo su -c "echo address $ADDRESS >> /etc/network/interfaces" 2>/dev/null
sudo su -c "echo netmask $NETMASK >> /etc/network/interfaces" 2>/dev/null
sudo su -c "echo gateway $GATEWAY >> /etc/network/interfaces" 2>/dev/null
sudo su -c "echo dns-nameservers 1.1.1.1 >> /etc/network/interfaces" 2>/dev/null

# CloudFlare DNS
sudo su -c 'echo "" > /etc/resolv.conf' 2>/dev/null
#sudo resolvconf -u
sudo su -c "echo 'nameserver $GATEWAY' >> /etc/resolv.conf" 2>/dev/null
sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf' 2>/dev/null
# China
sudo su -c 'echo "nameserver 114.114.114.114" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 114.114.115.115" >> /etc/resolv.conf' 2>/dev/null
# For msos versions what have local DNS cache
#sudo su -c 'echo "nameserver 127.0.0.1" >> /etc/resolv.conf' 2>/dev/null
# IPV6
sudo su -c 'echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf' 2>/dev/null
# systemd resolve casusing problems with 127.0.0.53
sudo su -c 'echo "nameserver 1.1.1.1" > /run/resolvconf/interface/systemd-resolved' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
sudo su -c 'echo "nameserver 1.1.1.1" > /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo options edns0 >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null

sudo su -c '/etc/init.d/networking restart'
sudo su -c "systemctl restart systemd-networkd"

echo ""
TEST="$(ping api.minerstat.com -w 1 | grep '1 packets transmitted')"

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
