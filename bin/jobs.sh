#!/bin/bash
exec 2>/dev/null
echo "Running Clean jobs ..."
TESTLOGIN=$(systemctl list-jobs)
if [ "$TESTLOGIN" != "systemctl list-jobs" ]; then
  sudo systemctl restart systemd-logind.service
fi
sudo systemctl mask apt-daily.service apt-daily-upgrade.service 
sudo apt-mark hold linux-generic linux-image-generic linux-headers-generic linux-firmware > /dev/null 2>&1
sudo systemctl daemon-reload
# Kernel panic auto reboot
sudo su -c "echo 20 >/proc/sys/kernel/panic"
# Remove logs
find '/home/minerstat/minerstat-os/clients/claymore-eth' -name "*log.txt" -type f -delete
sudo find /var/log -type f -name "*.journal" -delete
sudo su -c "sudo service rsyslog stop"
#sudo su -c "systemctl disable rsyslog"
#sudo su -c "systemctl disable wpa_supplicant"
#echo "Log files deleted"
sudo dmesg -n 1
sudo apt clean
# Apply crontab
sudo su -c "cp /home/minerstat/minerstat-os/core/minerstat /var/spool/cron/crontabs/minerstat"
sudo su -c "chmod 600 /var/spool/cron/crontabs/minerstat"
sudo su -c "chown minerstat /var/spool/cron/crontabs/minerstat"
sudo service cron restart
# Fix Slow start bug
sudo su -c "systemctl disable NetworkManager-wait-online.service"
sudo su -c "systemctl disable systemd-networkd-wait-online.service"
sudo sed -i s/"TimeoutStartSec=5min"/"TimeoutStartSec=5sec"/ /etc/systemd/system/network-online.target.wants/networking.service
sudo sed -i s/"timeout 300"/"timeout 5"/ /etc/dhcp/dhclient.conf
# Nvidia PCI_BUS_ID
sudo rm /etc/environment
sudo cp /home/minerstat/minerstat-os/core/environment /etc/environment
export CUDA_DEVICE_ORDER=PCI_BUS_ID
sudo su -c "export CUDA_DEVICE_ORDER=PCI_BUS_ID"
# libc-ares2 && libuv1-dev
# sudo apt-get --yes --force-yes install libcurl3/bionic | grep "install"
# Max performance
#export GPU_FORCE_64BIT_PTR=1 #causes problems
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100
export GPU_MAX_HEAP_SIZE=100
# Check SSH Keys
screen -A -m -d -S sshgens sudo /home/minerstat/minerstat-os/core/ressh &
# .bashrc
sudo cp -fR /home/minerstat/minerstat-os/core/.bashrc /home/minerstat
# rocm for VEGA
export HSA_ENABLE_SDMA=0
# Hugepages (XMR) [Need more test, this required or not]

FILE=/media/storage/hugepage.txt
if [ -f "$FILE" ]; then
  HPAGE=$(cat /media/storage/hugepage.txt)
  if [ -z "$HPAGE" ]; then
    HPAGE=128
  fi
else
  HPAGE=128
fi

sudo su -c "echo $HPAGE > /proc/sys/vm/nr_hugepages" > /dev/null 2>&1
sudo su -c "sysctl vm.nr_hugepages=$HPAGE" > /dev/null 2>&1
sudo su -c "echo always > /sys/kernel/mm/transparent_hugepage/enabled" > /dev/null 2>&1
sudo su -c "sysctl vm.dirty_background_ratio=20" > /dev/null 2>&1
sudo su -c "sysctl vm.dirty_expire_centisecs=0" > /dev/null 2>&1
sudo su -c "sysctl vm.dirty_ratio=80" > /dev/null 2>&1
sudo su -c "sysctl vm.dirty_writeback_centisecs=0" > /dev/null 2>&1
# Auto OpenCL for/above v1.5
version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`
if [ "$version" = "1.5" ] || [ "$version" = "1.6" ] || [ "$version" = "1.7" ]; then
  FILE=/media/storage/opencl.txt
  # If not exists then automatic openCL versioning
  if [ ! -f "$FILE" ]; then
    naviCount=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep -E "5500|5550|5600|5650|5700|5750|5800|5850|5900|5950" | wc -l)
    if [ "$naviCount" -gt "0" ]; then
      sudo su -c "echo '/opt/rocm-3.1.0/opencl/lib/x86_64/libamdocl64.so' > /etc/OpenCL/vendors/amdocl64.icd"
    else
      sudo su -c "echo '/opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl64.so' > /etc/OpenCL/vendors/amdocl64.icd"
    fi
  fi
fi
# Fix ERROR Messages
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# OpenCL
export OpenCL_ROOT=/opt/amdgpu-pro/lib/x86_64-linux-gnu
# FSCK
sudo sed -i s/"#FSCKFIX=no"/"FSCKFIX=yes"/ /etc/default/rcS
# check cloudflare ips
SERVERA="104.20.2.95"
SERVERB="104.20.3.95"
DNSA=$(ping -c 1 $SERVERA &> /dev/null && echo success || echo fail)
DNSB=$(ping -c 1 $SERVERB &> /dev/null && echo success || echo fail)
SERVERC="$SERVERB"
if [ "$DNSA" = "success" ] && [ "$DNSB" != "success" ]; then
        SERVERC="$SERVERA"
fi
if [ "$DNSA" != "success" ] && [ "$DNSB" = "success" ]; then
        SERVERC="$SERVERB"
fi
if [ "$DNSA" = "success" ] && [ "$DNSB" = "success" ]; then
        SERVERC="$SERVERB"
fi
if [ "$DNSA" != "success" ] && [ "$DNSB" != "success" ]; then
        SERVERC="$SERVERB"
fi
# Change hostname
sudo su -c "echo '$WNAME' > /etc/hostname"
sudo hostname -F /etc/hostname
# /etc/hosts
WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
sudo echo "
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.1.1 $WNAME
$SERVERC minerstat.com
$SERVERC api.minerstat.com
104.24.98.231 static-ssl.minerstat.farm
68.183.74.40 eu.pool.ms
167.71.240.6 us.pool.ms
68.183.74.40 eu.sandbox.pool.ms
167.71.240.6 us.sandbox.pool.ms
" > /etc/hosts
#sudo sed -i s/"minerstat"/"$WNAME"/ /etc/hosts
if grep -q $WNAME "/etc/hosts"; then
  echo ""
else
  echo " Hostname mismatch - FIXING.. "
  sudo su -c "sed -i '/127.0.1.1/d' /etc/hosts"
  sudo su -c "echo '127.0.1.1   $WNAME' >> /etc/hosts"
fi
#WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
#sudo sed -i s/"$WNAME"/"minerstat"/ /etc/hosts
#sudo su -c "echo 'minerstat' > /etc/hostname"
#sudo hostname -F /etc/hostname
# CloudFlare DNS
#sudo resolvconf -u
GET_GATEWAY=$(route -n -e -4 | awk {'print $2'} | grep -vE "0.0.0.0|IP|Gateway" | head -n1 | xargs)
# systemd resolve casusing problems with 127.0.0.53
if [ ! -z "$GET_GATEWAY" ]; then
  sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/resolvconf/interface/systemd-resolved" 2>/dev/null
fi
sudo su -c 'echo "nameserver 1.1.1.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.8.8" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.4.4" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
if [ ! -z "$GET_GATEWAY" ]; then
  sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/systemd/resolve/stub-resolv.conf" 2>/dev/null
fi
sudo su -c 'echo "nameserver 1.1.1.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.8.8" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.4.4" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
sudo su -c 'echo options edns0 >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
# Rewrite
sudo su -c 'echo "" > /etc/resolv.conf'
if [ ! -z "$GET_GATEWAY" ]; then
  sudo su -c "echo 'nameserver $GET_GATEWAY' >> /etc/resolv.conf" 2>/dev/null
fi
sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf' 2>/dev/null
# China
sudo su -c 'echo "nameserver 114.114.114.114" >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo "nameserver 114.114.115.115" >> /etc/resolv.conf' 2>/dev/null
# IPV6
sudo su -c 'echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf' 2>/dev/null
sudo su -c 'echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf' 2>/dev/null
# Memory Info
sudo chmod -R 777 * /home/minerstat/minerstat-os
sudo rm /home/minerstat/minerstat-os/bin/amdmeminfo.txt
sudo rm /dev/shm/amdmeminfo.txt

if [ -z "$1" ]; then
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
  #if [ "$AMDDEVICE" = "0" ]; then
  #  AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
  #fi
fi
# SSL off for bad timedate bioses
npm config set strict-ssl false
git config --global http.sslverify false
# Update motd.d
sudo chmod 777 /etc/update-motd.d/10-help-text
sudo cp /home/minerstat/minerstat-os/core/10-help-text /etc/update-motd.d
# Update tmux design
sudo cp /home/minerstat/minerstat-os/core/.tmux.conf /home/minerstat
# Tmate config
sudo cp /home/minerstat/minerstat-os/core/.tmate.conf /home/minerstat
echo "" | ssh-keygen -N "" &> /dev/null
#sudo killall tmate
#/home/minerstat/minerstat-os/bin/tmate -S /tmp/tmate.sock new-session -d
# Update profile
sudo chmod 777 /etc/profile
sudo cp /home/minerstat/minerstat-os/core/profile /etc
# Restart listener, Maintenance Process, Also from now it can be updated in runtime (mupdate)
sudo su -c "screen -S listener -X quit"
sudo su minerstat -c "screen -S listener -X quit"
sudo su minerstat -c "screen -A -m -d -S listener sudo bash /home/minerstat/minerstat-os/core/init.sh"
# Disable UDEVD & JOURNAL
sudo systemctl stop systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket
sudo systemctl disable systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket
sudo su -c "sudo rm -rf /var/log/journal; sudo ln -s /dev/shm /var/log/journal"
sudo systemctl start systemd-journald.service systemd-journald.socket systemd-journald-dev-log.socket
# Create Shortcut for JQ
sudo ln -s /home/minerstat/minerstat-os/bin/jq /sbin &> /dev/null
# Remove ppfeaturemask to avoid kernel panics with old cards
#sudo chmod 777 /boot/grub/grub.cfg && sudo su -c "sed -Ei 's/amdgpu.ppfeaturemask=0xffffffff//g' /boot/grub/grub.cfg" && sudo chmod 444 /boot/grub/grub.cfg
# Restart fan curve if running
FNUM=$(sudo su -c "screen -list | grep -c curve")
if [ "$FNUM" -gt "0" ]; then
  sudo killall curve
  sleep 0.1
  sudo kill -9 $(sudo pidof curve)
  sleep 0.2
  sudo screen -A -m -d -S curve /home/minerstat/minerstat-os/core/curve
fi
# Safety layer
CURVE_FILE=/media/storage/fans.txt
if [ -f "$CURVE_FILE" ]; then
  sudo killall curve
  sleep 0.1
  sudo kill -9 $(sudo pidof curve)
  sleep 0.1
  sudo screen -A -m -d -S curve /home/minerstat/minerstat-os/core/curve
fi
# Time Date SYNC
sudo timedatectl set-ntp on &
# NVIDIA
sudo getent group nvidia-persistenced &>/dev/null || sudo groupadd -g 143 nvidia-persistenced
sudo getent passwd nvidia-persistenced &>/dev/null || sudo useradd -c 'NVIDIA Persistence Daemon' -u 143 -g nvidia-persistenced -d '/' -s /sbin/nologin nvidia-persistenced
# Check XSERVER
SNUMD=$(sudo su minerstat -c "screen -list | grep -c display2")
if [ "$SNUMD" = "0" ]; then
  sudo su -c "sudo screen -X -S display quit" &
  sudo killall X
  sudo killall Xorg
  sudo kill -9 $(sudo pidof Xorg)
  sudo rm /tmp/.X0-lock
  sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
  sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
  sudo su minerstat -c "screen -A -m -d -S display2 sudo X"
fi
# Check CURL is installed
ISCURL=$(dpkg -l curl | grep curl | wc -l | sed 's/[^0-9]*//g')
if [ "$ISCURL" -lt 1 ]; then
  sudo apt --yes --force-yes --fix-broken install
  sudo apt-get --yes --force-yes install curl
fi
# install curl if required
which curl 2>/dev/null && curlPresent=true
if [ -z "${curlPresent:-}" ]; then
  echo "CURL FIX"
  sudo apt --yes --force-yes --fix-broken install
  sudo apt-get --yes --force-yes install curl libcurl4
  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
  fi
fi
# nvidia-settings fix for Segmentation fault
CHECKAPTXN=$(dpkg -l | grep "libegl1-amdgpu-pro" | wc -l)
if [ "$CHECKAPTXN" -gt "0" ]; then
  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
  fi
fi
if [ "$1" -gt 0 ] || [ "$AMDDEVICE" -gt 0 ]; then
  #sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q > /home/minerstat/minerstat-os/bin/amdmeminfo.txt &
  sudo chmod 777 /dev/shm/amdmeminfo.txt
  sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q | tac > /dev/shm/amdmeminfo.txt &
  sudo cp -rf /dev/shm/amdmeminfo.txt /home/minerstat/minerstat-os/bin
  sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
fi
if [ -f "/etc/netplan/minerstat.yaml" ]; then
  if grep -q dhcp-identifier "/etc/netplan/minerstat.yaml"; then
    echo ""
  else
    echo ""
    INTERFACE="$(sudo cat /proc/net/dev | grep -vE lo | tail -n1 | awk -F '\\:' '{print $1}' | xargs)"
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
  fi
fi
# Firmware for v1.2
if [ "$version" = "1.2" ]; then
  echo "Checking Firmware.."
  FILE=/media/storage/fw.txt
  if test -f "$FILE"; then
    echo "FW Updated"
  else
    echo "FW needs update"
    echo "Updating firmware.."
    cd /tmp; mkdir firmware; cd firmware; wget https://static-ssl.minerstat.farm/miners/linux-firmware.tar.gz; tar -xvf linux-firmware.tar.gz; rm linux-firmware.tar.gz; sudo cp -va * /lib/firmware/amdgpu; sudo update-initramfs -u; sync;
    sudo su -c "echo '1' > /media/storage/fw.txt"
  fi
fi
if [ "$version" = "1.4" ] || [ "$version" = "1.4.5" ]; then
  CHECK=$(ls /boot | grep "5.3.0" | wc -l)
  if [ "$CHECK" != "0" ]; then
    sudo rm -rf /boot/*5.3.0*
    echo "generating new grub"
    sudo update-grub2
    sync
  fi
  CHECK=$(ls /boot | grep "5.4.0" | wc -l)
  if [ "$CHECK" != "0" ]; then
    sudo rm -rf /boot/*5.4.0*
    echo "generating new grub"
    sudo update-grub2
    sync
  fi
  CHECK=$(ls /boot | grep "5.5.0" | wc -l)
  if [ "$CHECK" != "0" ]; then
    sudo rm -rf /boot/*5.4.0*
    echo "generating new grub"
    sudo update-grub2
    sync
  fi
  CHECK=$(ls /boot | grep "5.6.0" | wc -l)
  if [ "$CHECK" != "0" ]; then
    sudo rm -rf /boot/*5.6.0*
    echo "generating new grub"
    sudo update-grub2
    sync
  fi
fi
