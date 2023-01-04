#!/bin/bash
echo -e ""
echo -e "\033[1;34m=========== CONFIGURING DHCP ===========\033[0m"

# Wait
echo -e "\033[1;34m==\033[0m Networking: \033[1;32m Waiting for interfaces ... \033[0m"

# Restart networking
sudo su -c "/etc/init.d/networking restart" 1>/dev/null

# Sleep
sleep 2
echo -e "\033[1;34m==\033[0m Networking: \033[1;32m Configuring the interfaces ... \033[0m"
sleep 2

CHECK_IF=$(sudo ifconfig)
IFACE_LIST=""

# Eth0
INTERFACE="$(sudo timeout 15 cat /proc/net/dev | grep -vE "lo|docker0|wlan0|face|Inter" | tail -n1 | awk -F '\\:' '{print $1}' | xargs)"
if [[ "$CHECK_IF" == *"$INTERFACE"* ]]; then
  echo "    $INTERFACE found in ifconfig list."
  IFACE_LIST="$INTERFACE "
fi

# Eth1
INTERFACE="$(sudo timeout 15 cat /proc/net/dev | grep -vE "lo|docker0|wlan0|face|Inter" | tail -n2 | awk -F '\\:' '{print $1}' | xargs | cut -d " " -f1 | xargs)"
if [[ "$CHECK_IF" == *"$INTERFACE"* ]] && [[ "$IFACE_LIST" != *"$INTERFACE"* ]]; then
  echo "    $INTERFACE found in ifconfig list."
  IFACE_LIST="$INTERFACE $IFACE_LIST "
fi
  
# Eth2
INTERFACE="$(sudo timeout 15 cat /proc/net/dev | grep -vE "lo|docker0|wlan0|face|Inter" | tail -n3 | awk -F '\\:' '{print $1}' | xargs | cut -d " " -f1 | xargs)"
if [[ "$CHECK_IF" == *"$INTERFACE"* ]] && [[ "$IFACE_LIST" != *"$INTERFACE"* ]]; then
  echo "    $INTERFACE found in ifconfig list."
  IFACE_LIST="$INTERFACE $IFACE_LIST "
fi

# Failover if some reason nothing detected
if [[ -z "$IFACE_LIST" ]]; then 
  IFACE_LIST="eth0"
fi

if [[ -z "$INTERFACE" ]]; then 
  INTERFACE="eth0"
fi

echo -e "\033[1;34m==\033[0m DHCP Interfaces: \033[1;32m $IFACE_LIST \033[0m"
echo -e ""

NSCHECK=$(cat /etc/resolv.conf | grep 'nameserver 1.1.1.1' | xargs)
if [ "$NSCHECK" != "nameserver 1.1.1.1" ]; then
  sudo su -c 'echo -n > /etc/resolv.conf; echo -e "nameserver 1.1.1.1" >> /etc/resolv.conf; echo -e "nameserver 1.0.0.1" >> /etc/resolv.conf; echo -e "nameserver 8.8.8.8" >> /etc/resolv.conf; echo -e "nameserver 8.8.4.4" >> /etc/resolv.conf; echo -e "nameserver 114.114.114.114" >> /etc/resolv.conf; echo -e "nameserver 114.114.115.115" >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf;' 2>/dev/null
fi

NETRESTART="NO"

N="echo -n > /etc/network/interfaces;"
for iface in $IFACE_LIST; do
  IFACE1=$(cat /etc/network/interfaces | grep "allow-hotplug $iface" | xargs)
  IFACE2=$(cat /etc/network/interfaces | grep "iface $iface inet dhcp" | xargs)
  if [ "$IFACE1" != "allow-hotplug $iface" ] || [ "$IFACE2" != "iface $iface inet dhcp" ]; then
    sudo su -c "$N echo allow-hotplug $iface >> /etc/network/interfaces; echo iface $iface inet dhcp >> /etc/network/interfaces;" 2>/dev/null
    N=""
    NETRESTART="YES"
  fi
done

sudo su -c "/etc/init.d/networking restart" 1>/dev/null

if [ "$NETRESTART" = "YES" ]; then
  sudo su -c "systemctl restart systemd-networkd" 1>/dev/null
  sudo su -c "/etc/init.d/networking restart" 1>/dev/null
fi

# UP
for iface in $IFACE_LIST; do
IFACESTATUS=$(sudo timeout 5 /sbin/ifconfig $INTERFACE | grep "UP," | xargs)
  #if [[ "$IFACESTATUS" != *"UP,"* ]]; then
    sudo ifconfig $iface 0.0.0.0 0.0.0.0
    sudo ifconfig $iface down
    timeout 10 sudo ifconfig $iface up
    sleep 1
  #fi
done

if [[ "$IFACE_LIST" == *"eth"* ]]; then
  sudo echo "network:" > /etc/netplan/minerstat.yaml
  sudo echo " version: 2" >> /etc/netplan/minerstat.yaml
  sudo echo " renderer: networkd" >> /etc/netplan/minerstat.yaml
  sudo echo " ethernets:" >> /etc/netplan/minerstat.yaml
  if [[ "$IFACE_LIST" == *"eth0"* ]]; then
    sudo echo "   eth0:" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp4: yes" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp-identifier: mac" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp6: no" >> /etc/netplan/minerstat.yaml
    sudo echo "     nameservers:" >> /etc/netplan/minerstat.yaml
    sudo echo "         addresses: [1.1.1.1, 1.0.0.1]" >> /etc/netplan/minerstat.yaml
  fi
  if [[ "$IFACE_LIST" == *"eth1"* ]]; then
    sudo echo "   eth2:" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp4: yes" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp-identifier: mac" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp6: no" >> /etc/netplan/minerstat.yaml
    sudo echo "     nameservers:" >> /etc/netplan/minerstat.yaml
    sudo echo "         addresses: [1.1.1.1, 1.0.0.1]" >> /etc/netplan/minerstat.yaml
  fi
  if [[ "$IFACE_LIST" == *"eth2"* ]]; then
    sudo echo "   eth2:" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp4: yes" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp-identifier: mac" >> /etc/netplan/minerstat.yaml
    sudo echo "     dhcp6: no" >> /etc/netplan/minerstat.yaml
    sudo echo "     nameservers:" >> /etc/netplan/minerstat.yaml
    sudo echo "         addresses: [1.1.1.1, 1.0.0.1]" >> /etc/netplan/minerstat.yaml
  fi
  sudo timeout 5 /usr/sbin/netplan apply
fi

# Run dhclient just in case
sudo timeout 20 sudo dhclient

# Validate
sleep 1

echo -e "\033[1;34m==\033[0m Networking: \033[1;32m Validating the connection ... \033[0m"

TEST="$(ping api.minerstat.com -w 1 | grep '1 packets transmitted' | xargs)"
if [[ "$TEST" == *"0% packet loss"* ]]; then
  echo -e ""
  echo -e "\033[1;34m==\033[0m Internet connection: \033[1;32mONLINE\033[0m"
else
  echo -e ""
  echo -e "\033[1;34m==\033[0m Internet connection: \033[1;31mOFFLINE\033[0m"
  NETRESTART="YES"
fi