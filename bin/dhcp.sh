#!/bin/bash
echo -e ""
echo -e "\033[1;34m=========== CONFIGURING DHCP ===========\033[0m"

INTERFACE="$(sudo cat /proc/net/dev | grep -vE "lo|docker0" | tail -n1 | awk -F '\\:' '{print $1}' | xargs)"

echo -e "\033[1;34m==\033[0m DHCP Interface: \033[1;32m$INTERFACE\033[0m"
echo -e ""

NSCHECK=$(cat /etc/resolv.conf | grep 'nameserver 1.1.1.1' | xargs)
if [ "$NSCHECK" != "nameserver 1.1.1.1" ]; then
  sudo su -c 'echo -n > /etc/resolv.conf; echo -e "nameserver 1.1.1.1" >> /etc/resolv.conf; echo -e "nameserver 1.0.0.1" >> /etc/resolv.conf; echo -e "nameserver 8.8.8.8" >> /etc/resolv.conf; echo -e "nameserver 8.8.4.4" >> /etc/resolv.conf; echo -e "nameserver 114.114.114.114" >> /etc/resolv.conf; echo -e "nameserver 114.114.115.115" >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf;' 2>/dev/null
fi

NETRESTART="NO"
IFACE=$(cat /etc/network/interfaces | grep "allow-hotplug $INTERFACE" | xargs)
if [ "$IFACE" != "allow-hotplug $INTERFACE" ]; then
  sudo su -c "echo -n > /etc/network/interfaces; echo allow-hotplug $INTERFACE >> /etc/network/interfaces" 2>/dev/null
  NETRESTART="YES"
fi

IFACE=$(cat /etc/network/interfaces | grep "iface $INTERFACE inet dhcp" | xargs)
if [ "$IFACE" != "iface $INTERFACE inet dhcp" ]; then
  sudo su -c "echo iface $INTERFACE inet dhcp >> /etc/network/interfaces" 2>/dev/null
  NETRESTART="YES"
fi

IFACESTATUS=$(sudo /sbin/ifconfig $INTERFACE | grep "UP," | xargs)
if [[ "$IFACESTATUS" != *"UP,"* ]]; then
  sudo ifdown $INTERFACE
  sudo nohup ifup $INTERFACE &
  sleep 4
fi

TEST="$(ping api.minerstat.com -w 1 | grep '1 packets transmitted' | xargs)"
if [[ "$TEST" == *"0% packet loss"* ]]; then
  echo -e ""
  echo -e "\033[1;34m==\033[0m Internet connection: \033[1;32mONLINE\033[0m"
else
  echo -e ""
  echo -e "\033[1;34m==\033[0m Internet connection: \033[1;31mOFFLINE\033[0m"
  NETRESTART="YES"
fi

if [ "$NETRESTART" = "YES" ]; then
  sudo su -c "/etc/init.d/networking restart; systemctl restart systemd-networkd" 2>/dev/null
fi

if [ "$INTERFACE" = "eth0" ]; then
  sudo echo "network:" > /etc/netplan/minerstat.yaml
  sudo echo " version: 2" >> /etc/netplan/minerstat.yaml
  sudo echo " renderer: networkd" >> /etc/netplan/minerstat.yaml
  sudo echo " ethernets:" >> /etc/netplan/minerstat.yaml
  sudo echo "   eth0:" >> /etc/netplan/minerstat.yaml
  sudo echo "     dhcp4: yes" >> /etc/netplan/minerstat.yaml
  sudo echo "     dhcp-identifier: mac" >> /etc/netplan/minerstat.yaml
  sudo echo "     dhcp6: no" >> /etc/netplan/minerstat.yaml
  sudo echo "     nameservers:" >> /etc/netplan/minerstat.yaml
  sudo echo "         addresses: [1.1.1.1, 1.0.0.1]" >> /etc/netplan/minerstat.yaml
  sudo /usr/sbin/netplan apply
fi
