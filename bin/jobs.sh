#!/bin/bash
exec 2>/dev/null
echo "Running Clean jobs ..."
TESTLOGIN=$(timeout 2 systemctl list-jobs)
if [ "$TESTLOGIN" != "No jobs running." ]; then
  sudo systemctl restart systemd-logind.service &
fi
CL=/media/storage/opencl.txt
if [ ! -f "$CL" ]; then
  sudo su -c "echo 'amd' > $CL; echo '/opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl64.so' > /etc/OpenCL/vendors/amdocl64.icd"
  echo "OpenCL switched to: amdgpu"
fi
#START SOCKET
# Only start if no sockets instance running
#SNUM=$(sudo su minerstat -c "screen -list | grep -c sockets")
#if [ "$SNUM" -lt "1" ]; then
#sudo su minerstat -c "screen -ls | grep sockets | cut -d. -f1 | awk '{print $1}' | xargs kill -9; screen -wipe; sudo killall sockets; screen -A -m -d -S sockets sudo bash /home/minerstat/minerstat-os/core/sockets" > /dev/null
#fi
#END SOCKET
timeout 10 sudo systemctl mask apt-daily.service apt-daily-upgrade.service > /dev/null &
timeout 10 sudo apt-mark hold linux-generic linux-image-generic linux-headers-generic linux-firmware > /dev/null &
timeout 10 sudo systemctl disable thermald systemd-timesyncd.service > /dev/null &
timeout 10 sudo systemctl stop thermald systemd-timesyncd.service > /dev/null &
AUTOLOGIN=$(cat /lib/systemd/system/getty@.service | grep autologin)
AUTOLOGINE=$(cat /lib/systemd/system/getty@.service | grep -c ExecStart)
if [[ -z "$AUTOLOGIN" ]] || [[ "$AUTOLOGINE" != "1" ]]; then
  echo "Applying autologin settings.."
  sudo sed -i '/ExecStart/d' /lib/systemd/system/getty@.service
  sudo sed -i '/Type=idle/ i ExecStart=-/sbin/agetty --autologin minerstat --noclear %I $TERM' /lib/systemd/system/getty@.service
  timeout 10 sudo systemctl daemon-reload
  timeout 10 sudo systemctl restart getty@tty1
fi
timeout 10 sudo systemctl daemon-reload > /dev/null &
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
sudo apt clean &
# Apply crontab + Fix slow start
sudo su -c "cp /home/minerstat/minerstat-os/core/minerstat /var/spool/cron/crontabs/minerstat; chmod 600 /var/spool/cron/crontabs/; chown minerstat /var/spool/cron/crontabs/minerstat; systemctl disable NetworkManager-wait-online.service; systemctl disable systemd-networkd-wait-online.service"
sudo chmod 1730 /var/spool/cron/crontabs
sudo chown root:crontab /var/spool/cron/crontabs
sudo service cron restart
sudo sed -i s/"TimeoutStartSec=5min"/"TimeoutStartSec=5sec"/ /etc/systemd/system/network-online.target.wants/networking.service
sudo sed -i s/"timeout 300"/"timeout 5"/ /etc/dhcp/dhclient.conf
# remove wget logs
timeout 3 sudo rm -rf /home/minerstat/minerstat-os/wget-log*
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

FILE_NVFLASH=/home/minerstat/minerstat-os/core2
if [ -d "$FILE_NVFLASH" ]; then
  sudo mv /home/minerstat/minerstat-os/core2 /home/minerstat/minerstat-os/core
fi

sudo su -c "echo $HPAGE > /proc/sys/vm/nr_hugepages; sysctl vm.nr_hugepages=$HPAGE; echo always > /sys/kernel/mm/transparent_hugepage/enabled; sysctl vm.dirty_background_ratio=20; sysctl vm.dirty_expire_centisecs=0; sysctl vm.dirty_ratio=80; sysctl vm.dirty_writeback_centisecs=0" > /dev/null 2>&1
# Auto OpenCL for/above v1.5
version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`

# Fix ERROR Messages
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# OpenCL
export OpenCL_ROOT=/opt/amdgpu-pro/lib/x86_64-linux-gnu
# FSCK
sudo sed -i s/"#FSCKFIX=no"/"FSCKFIX=yes"/ /etc/default/rcS
# check cloudflare ips
SERVERA="104.26.9.16"
SERVERB="104.26.8.16"
SERVERC="$SERVERB"
DNSA=$(ping -c 1 $SERVERA &> /dev/null && echo success || echo fail)
if [ "$DNSA" = "success" ]; then
  SERVERC="$SERVERA"
fi

# Change hostname
# /etc/hosts
HCHECK=$(cat /etc/hosts | grep "$SERVERC minerstat.com" | xargs)
WCHECK=$(cat /etc/hosts | grep "127.0.1.1 $WNAME" | xargs)

CURRENT_DATE=$(date +'%Y-%m-%d %H:00')
CCHECK=$(cat /home/minerstat/cache_date 2>/dev/null)
echo "#!/bin/bash" > /home/minerstat/clock_cache

WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
if [ "$HCHECK" != "$SERVERC minerstat.com" ] || [ "$WCHECK" != "127.0.1.1 $WNAME" ] || [ "$CCHECK" != "$CURRENT_DATE" ]; then
  sudo su -c "echo '$WNAME' > /etc/hostname"
  sudo hostname -F /etc/hostname
  sudo echo "
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.1.1 $WNAME
$SERVERC minerstat.com
$SERVERC www.minerstat.com
$SERVERC api.minerstat.com
104.26.1.235 static-ssl.minerstat.farm
68.183.74.40 eu.pool.ms
167.71.240.6 us.pool.ms
68.183.74.40 eu.sandbox.pool.ms
167.71.240.6 us.sandbox.pool.ms
162.159.200.1 ntp.ubuntu.com
104.26.1.235 labs.minerstat.farm
  " > /etc/hosts
  # Manage CACHE
  sudo rm /home/minerstat/mining-pool-whitelist.txt 2>/dev/null
  wget -o /dev/null https://minerstat.com/mining-pool-whitelist.txt -O /home/minerstat/mining-pool-whitelist.txt
  if [ $? -ne 0 ]; then
    echo "Cache wget failed. Trying next time"
  else
    TEST=$(sudo wc -c /home/minerstat/mining-pool-whitelist.txt | awk '{print $1}')
    TEST2=$(cat /home/minerstat/mining-pool-whitelist.txt | grep -c "ethermine")
    TEST3=$(cat /home/minerstat/mining-pool-whitelist.txt | grep -c "2miners")
    TEST4=$(cat /home/minerstat/mining-pool-whitelist.txt | grep -c "nanopool")
    if [[ "$TEST" -gt 1000 ]] && [[ "$TEST2" -gt 0 ]] && [[ "$TEST3" -gt 0 ]] && [[ "$TEST4" -gt 0 ]]; then
      echo "Cache valid"
      sudo cat /home/minerstat/mining-pool-whitelist.txt >> /etc/hosts
      sudo echo "$CURRENT_DATE" > /home/minerstat/cache_date
      sync &
    fi
  fi
fi

GET_GATEWAY=$(timeout 5 route -n -e -4 | awk {'print $2'} | grep -vE "0.0.0.0|IP|Gateway" | head -n1 | xargs)
NSCHECK=$(cat /etc/resolv.conf | grep "nameserver 1.1.1.1" | xargs)
RES_TEST=$(timeout 5 ping -c1 l.root-servers.net > /dev/null && echo "ok" || echo "failed")
if [ "$NSCHECK" != "nameserver 1.1.1.1" ] || [ ! -z "$GET_GATEWAY" ] || [ "$RES_TEST" = "failed" ]; then
  #GCHECK=$(cat /etc/resolv.conf | grep "nameserver $GET_GATEWAY" | xargs)
  if [ ! -z "$GET_GATEWAY" ]; then
    # Detect IP blocker DNS
    BLOCK_TEST=$(timeout 5 nslookup eu1.ethermine.org $GET_GATEWAY | grep Address: | grep "0.0.0.0" | head -n1 | awk '{print $2}' | xargs | xargs)
    if [ "$BLOCK_TEST" = "0.0.0.0" ]; then
      sudo su -c "echo -n > /etc/resolv.conf; echo 'nameserver 1.1.1.1' >> /etc/resolv.conf; echo 'nameserver 1.0.0.1' >> /etc/resolv.conf; echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; echo 'nameserver 8.8.4.4' >> /etc/resolv.conf; echo 'nameserver 114.114.114.114' >> /etc/resolv.conf; echo 'nameserver 114.114.115.115' >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf;" 2>/dev/null
    else
      sudo su -c "echo -n > /etc/resolv.conf; echo 'nameserver $GET_GATEWAY' >> /etc/resolv.conf; echo 'nameserver 1.1.1.1' >> /etc/resolv.conf; echo 'nameserver 1.0.0.1' >> /etc/resolv.conf; echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; echo 'nameserver 8.8.4.4' >> /etc/resolv.conf; echo 'nameserver 114.114.114.114' >> /etc/resolv.conf; echo 'nameserver 114.114.115.115' >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf;" 2>/dev/null
    fi
  else
    sudo su -c "echo -n > /etc/resolv.conf; echo 'nameserver 1.1.1.1' >> /etc/resolv.conf; echo 'nameserver 1.0.0.1' >> /etc/resolv.conf; echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; echo 'nameserver 8.8.4.4' >> /etc/resolv.conf; echo 'nameserver 114.114.114.114' >> /etc/resolv.conf; echo 'nameserver 114.114.115.115' >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf; echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf" 2>/dev/null
  fi
fi

# Memory Info
timeout 5 sudo chmod -R 777 * /home/minerstat/minerstat-os

if [ -z "$1" ]; then
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
  #if [ "$AMDDEVICE" = "0" ]; then
  #  AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
  #fi
fi
# SSL off for bad timedate bioses
timeout 5 npm config set strict-ssl false
timeout 5 git config --global http.sslverify false
# Update motd.d
timeout 5 sudo chmod 777 /etc/update-motd.d/10-help-text
timeout 5 sudo cp /home/minerstat/minerstat-os/core/10-help-text /etc/update-motd.d
# Update tmux design
if [ "$version" = "1.6.0" ]; then
  sudo cp -f /home/minerstat/minerstat-os/core/.tmux2.conf /home/minerstat/.tmux.conf
else
  sudo cp -f /home/minerstat/minerstat-os/core/.tmux.conf /home/minerstat
fi
# Tmate config
sudo cp /home/minerstat/minerstat-os/core/.tmate.conf /home/minerstat
echo "" | ssh-keygen -N "" &> /dev/null
# ssh pam
sudo chmod -R 600 /etc/ssh
TESTPAM=$(sudo cat /etc/ssh/sshd_config | grep UsePAM)
if [[ ! -z "$TESTPAM" ]] && [[ $TESTPAM == *"no"* ]]; then
  sudo sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
  sudo service sshd restart > /dev/null
fi
#sudo killall tmate
#/home/minerstat/minerstat-os/bin/tmate -S /tmp/tmate.sock new-session -d
# Update profile
sudo chmod 777 /etc/profile
sudo cp /home/minerstat/minerstat-os/core/profile /etc
# Restart listener, Maintenance Process, Also from now it can be updated in runtime (mupdate)
timeout 5 sudo su -c "screen -S listener -X quit" > /dev/null
timeout 5 sudo su minerstat -c "screen -S listener -X quit" > /dev/null
timeout 5 sudo su minerstat -c "screen -A -m -d -S listener sudo bash /home/minerstat/minerstat-os/core/init.sh"
# Disable UDEVD & JOURNAL
timeout 5 sudo systemctl stop systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket
timeout 5 sudo systemctl disable systemd-udevd systemd-udevd-kernel.socket systemd-udevd-control.socket
timeout 5 sudo su -c "sudo rm -rf /var/log/journal; sudo ln -s /dev/shm /var/log/journal"
timeout 5 sudo systemctl start systemd-journald.service systemd-journald.socket systemd-journald-dev-log.socket
# Create Shortcut for JQ
sudo ln -s /home/minerstat/minerstat-os/bin/jq /sbin &> /dev/null
# Remove ppfeaturemask to avoid kernel panics with old cards
#sudo chmod 777 /boot/grub/grub.cfg && sudo su -c "sed -Ei 's/amdgpu.ppfeaturemask=0xffffffff//g' /boot/grub/grub.cfg" && sudo chmod 444 /boot/grub/grub.cfg
# Restart fan curve if running
FNUM=$(sudo su -c "screen -list | grep -c curve")
if [ "$FNUM" -gt "0" ]; then
  sudo killall curve > /dev/null
  sleep 0.1
  sudo kill -9 $(sudo pidof curve) > /dev/null
  sleep 0.2
  sudo screen -A -m -d -S curve /home/minerstat/minerstat-os/core/curve
fi
# Safety layer
CURVE_FILE=/media/storage/fans.txt
if [ -f "$CURVE_FILE" ]; then
  sudo killall curve > /dev/null
  sleep 0.1
  sudo kill -9 $(sudo pidof curve) > /dev/null
  sleep 0.1
  sudo screen -A -m -d -S curve /home/minerstat/minerstat-os/core/curve
fi
# Time Date SYNC
timeout 5 sudo timedatectl set-ntp on &
DATES=$(timeout 3 wget -o /dev/null -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)
if [[ ! -z "$DATES" ]]; then
  sudo date -s "$(echo $DATES)Z"
else
  DATES=$(timeout 3 wget -o /dev/null -qSO- --max-redirect=0 www.minerstat.com 2>&1 | grep Date: | cut -d' ' -f5-8)
  if [[ ! -z "$DATES" ]]; then
    sudo date -s "$(echo $DATES)Z"
  fi
fi
# Copy PCIIDS
yes | sudo cp -rf /home/minerstat/minerstat-os/core/pci.ids /usr/share/misc
# NVIDIA
timeout 5 sudo getent group nvidia-persistenced &>/dev/null || sudo groupadd -g 143 nvidia-persistenced &
timeout 5 sudo getent passwd nvidia-persistenced &>/dev/null || sudo useradd -c 'NVIDIA Persistence Daemon' -u 143 -g nvidia-persistenced -d '/' -s /sbin/nologin nvidia-persistenced &
# Safety check for sockets, if double instance kill
SNUM=$(sudo su minerstat -c "screen -list | grep -c sockets")
if [ "$SNUM" != "1" ]; then
  sudo su minerstat -c "screen -ls | grep sockets | cut -d. -f1 | awk '{print $1}' | xargs kill -9; screen -wipe; sudo killall sockets; sleep 0.5; sudo killall sockets; screen -A -m -d -S sockets sudo bash /home/minerstat/minerstat-os/core/sockets" > /dev/null
fi
# Check for watchdogs
SNUM=$(sudo su minerstat -c "screen -list | grep -c usbdog")
if [ "$SNUM" != "1" ]; then
  sudo su minerstat -c "screen -ls | grep usbdog | cut -d. -f1 | awk '{print $1}' | xargs kill -9; screen -wipe; sudo killall usbdog; sleep 0.5; sudo killall usbdog; screen -A -m -d -S usbdog sudo bash /home/minerstat/minerstat-os/watchdog" > /dev/null
fi
# TCP segmentation offload
TSOT=$(timeout 5 ethtool -k eth0 | grep tcp-segmentation-offload | xargs)
if [[ -z "$TSOT" ]] && [[ $TSOT != *"off"* ]]; then
  TETH=$(which ethtool)
  if [[ -z "$TETH" ]]; then
    timeout 5 sudo ethtool -K eth0 tso off
  fi
fi
# Check XSERVER
NVIDIADEVICE=$(sudo lshw -C display | grep "driver=nvidia" | wc -l)
if [ "$NVIDIADEVICE" = "0" ]; then
  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
fi
if [ "$NVIDIADEVICE" != "0" ]; then
  #if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
  DONVIDIA="YES"
  # Check XSERVER
  XORG=$(timeout 5 nvidia-smi | grep -c Xorg)
  SNUM=$(sudo su minerstat -c "screen -list | grep -c display2")
  # Unknown Error
  FANMAX=$(cat /media/storage/fans.txt 2>/dev/null | grep "FANMAX=" | xargs | sed 's/[^0-9]*//g')
  if [ -z "$FANMAX" ]; then
    FANMAX=70
  fi
  timeout 10 sudo rm /dev/shm/nverr.txt &> /dev/null
  CHECK_ERR=$(timeout 10 sudo nvidia-settings --verbose -c :0 -a GPUFanControlState=1 -a GPUTargetFanSpeed="$FANMAX" &> /dev/shm/nverr.txt)
  CHECK_ERR=$(cat /dev/shm/nverr.txt | grep -c "Unknown Error")
  if [[ "$SNUM" != "1" ]] || [[ "$XORG" -lt 1 ]] || [[ "$XORG" -lt $NVIDIADEVICE ]] || [[ "$CHECK_ERR" -gt 0 ]]; then
    sudo su -c "timeout 10 sudo screen -X -S display quit" > /dev/null
    timeout 10 screen -X -S display quit > /dev/null
    timeout 10 screen -X -S display2 quit > /dev/null
    sudo timeout 10 killall X > /dev/null
    sudo timeout 10 killall Xorg > /dev/null
    sudo timeout 5 kill -9 $(sudo pidof Xorg) > /dev/null
    sudo timeout 5 rm /tmp/.X0-lock > /dev/null
    echo "device num: $NVIDIADEVICE"
    if [[ "$NVIDIADEVICE" -gt 1 ]]; then
      sudo timeout 10 nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0" --custom-edid="DFP-0:/home/minerstat/minerstat-os/bin/edid.bin" --preserve-driver-name --enable-all-gpus
    else
      sudo timeout 10 nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0" --custom-edid="DFP-0:/home/minerstat/minerstat-os/bin/edid.bin" --preserve-driver-name
    fi
    sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf > /dev/null
    sudo su minerstat -c "screen -A -m -d -S display2 sudo X :0" > /dev/null
  fi
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
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
  fi
fi
# nvidia-settings fix for Segmentation fault
CHECKAPTXN=$(dpkg -l | grep "libegl1-amdgpu-pro" | wc -l)
if [ "$CHECKAPTXN" -gt "0" ]; then
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
  fi
fi
if [ "$1" -gt 0 ] || [ "$AMDDEVICE" -gt 0 ]; then
  #sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q > /home/minerstat/minerstat-os/bin/amdmeminfo.txt &
  TEST=$(cat /dev/shm/amdmeminfo.txt)
  if [ -z "$TEST" ]; then
    timeout 5 sudo rm /home/minerstat/minerstat-os/bin/amdmeminfo.txt
    timeout 5 sudo rm /dev/shm/amdmeminfo.txt
    sudo chmod 777 /dev/shm/amdmeminfo.txt
    timeout 30 sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -q > /dev/shm/amdmeminfo.txt &
    sudo chmod 777 /dev/shm/amdmeminfo.txt
    # fix issue with meminfo file
    RBC=$(cat /dev/shm/amdmeminfo.txt)
    if [[ $RBC == *"libamdocl"* ]]; then
      sed -i '/libamdocl/d' /dev/shm/amdmeminfo.txt
    fi
    sudo cp -rf /dev/shm/amdmeminfo.txt /home/minerstat/minerstat-os/bin
    sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
  fi
  CHECKPY=$(dpkg -l | grep python3-pip)
  if [[ -z $CHECKPY ]]; then
    sudo apt-get update
    sudo apt-get -y install python3-pip --fix-missing
    sudo su minerstat -c "pip3 install setuptools"
    sudo su minerstat -c "pip3 install upp"
  fi
  # Check UPP installed
  FILE=/home/minerstat/.local/bin/upp
  if [ -f "$FILE" ]; then
    echo "UPP exists."
  else
    sudo su minerstat -c "pip3 install setuptools"
    sudo su minerstat -c "pip3 install upp"
  fi
fi
if [ -f "/etc/netplan/minerstat.yaml" ]; then
  if grep -q dhcp-identifier "/etc/netplan/minerstat.yaml"; then
    echo ""
  else
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
    cd /tmp; mkdir firmware; cd firmware; wget -o /dev/null https://static-ssl.minerstat.farm/miners/linux-firmware.tar.gz; tar -xvf linux-firmware.tar.gz; rm linux-firmware.tar.gz; sudo cp -va * /lib/firmware/amdgpu; sudo update-initramfs -u; sync;
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
