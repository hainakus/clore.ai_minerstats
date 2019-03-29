#!/bin/bash
exec 2>/dev/null
echo "Running Clean jobs.."
find '/home/minerstat/minerstat-os' -name "*log.txt" -type f -delete
sudo find /var/log -type f -name "*.journal" -delete
#echo "Log files deleted"
sudo dmesg -n 1
sudo apt clean
# Fix Slow start bug
sudo systemctl disable NetworkManager-wait-online.service
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
# .bashrc
sudo cp -fR /home/minerstat/minerstat-os/core/.bashrc /home/minerstat
# rocm for VEGA
export HSA_ENABLE_SDMA=0
# Hugepages (XMR) [Need more test, this required or not]
sudo su -c "echo 128 > /proc/sys/vm/nr_hugepages"
sudo su -c "sysctl -w vm.nr_hugepages=128"
# Fix ERROR Messages
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# OpenCL
export OpenCL_ROOT=/opt/amdgpu-pro/lib/x86_64-linux-gnu
# FSCK
sudo sed -i s/"#FSCKFIX=no"/"FSCKFIX=yes"/ /etc/default/rcS
# TELEPROXY
cd /home/minerstat/minerstat-os/bin
sudo su minerstat -c "screen -A -m -d -S telp sh teleconsole.sh"
# Change hostname
WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
sudo sed -i s/"minerstat"/"$WNAME"/ /etc/hosts
sudo su -c "echo '$WNAME' > /etc/hostname"
sudo hostname -F /etc/hostname
#WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
#sudo sed -i s/"$WNAME"/"minerstat"/ /etc/hosts
#sudo su -c "echo 'minerstat' > /etc/hostname"
#sudo hostname -F /etc/hostname
# CloudFlare DNS
sudo echo "" > /etc/resolv.conf
sudo echo "nameserver 1.1.1.1" >> /etc/resolv.conf
sudo echo "nameserver 1.0.0.1" >> /etc/resolv.conf
sudo echo "nameserver 8.8.8.8" >> /etc/resolv.conf
sudo echo "nameserver 8.8.4.4" >> /etc/resolv.conf
sudo resolvconf -u
sudo chmod -R 777 * /home/minerstat/minerstat-os
sudo rm /home/minerstat/minerstat-os/bin/amdmeminfo.txt

if [ -z "$1" ]; then
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
fi

if [ "$1" -gt 0 ] || [ "$AMDDEVICE" -gt 0 ]; then
        sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q > /home/minerstat/minerstat-os/bin/amdmeminfo.txt
        sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
fi

# Update motd.d
sudo chmod 777 /etc/update-motd.d/10-help-text
sudo cp /home/minerstat/minerstat-os/core/10-help-text /etc/update-motd.d
# Update tmux design
sudo cp /home/minerstat/minerstat-os/core/.tmux.conf /home/minerstat
