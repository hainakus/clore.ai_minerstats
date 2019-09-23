#!/bin/bash

OFFLINE_COUNT=0
OFFLINE_NUM=40
IS_ONLINE="YES"
DETECT="$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g' | sed 's/[0-9]*//g' | head -n1 | xargs)"
PART=$DETECT"1"

if [ "$DETECT" = "nvmenp" ]; then
    echo "Changeing header, NVM drive detected.."
    DETECT="$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g' | xargs | sed 's/.$//' | sed 's/\s.*$//' | xargs | sed 's/\p//g')"
    PART=$DETECT"p1"
fi

DISK="$(df -hm | grep $PART | awk '{print $2}')"

MONITOR_TYPE="unknown"
STRAPFILENAME="amdmemorytweak-stable"
DETECTA=$(nvidia-smi -L | grep "GPU 0:" | wc -l)
DETECTB=$(sudo lshw -C display | grep AMD | wc -l)

if grep -q experimental "/etc/lsb-release"; then
  STRAPFILENAME="amdmemorytweak"
fi

if [ "$DETECTA" -gt "0" ]; then
  echo "Hardware Monitor: Nvidia GPU found"
  MONITOR_TYPE="nvidia"
fi

if [ "$DETECTB" -gt "0" ]; then
  echo "Hardware Monitor: AMD GPU found"
  MONITOR_TYPE="amd"
fi

# Extended Query without loop
MOBO_TYPE=$(sudo dmidecode --string baseboard-product-name)
if [ "$MOBO_TYPE" = "Default string" ]; then
  MOBO_TYPE="Unbranded"
fi
BIOS_VERSION=$(sudo dmidecode --string bios-version)
MSOS_VERSION=$(cat /etc/lsb-release | grep DISTRIB_RELEASE= | head -n1 | sed 's/DISTRIB_RELEASE=//g')
MAC_ADDRESS=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address)
if [ -z "$MAC_ADDRESS" ]; then
  MAC_ADDRESS=$(ifconfig -a | grep : | grep -vE "eth0|lo|wlan0" | grep ether | awk '{print $2}')
fi
CPU_TYPE=$(sudo dmidecode --string processor-version)
DISK_TYPE=$(lsblk -io KNAME,MODEL,SIZE | grep $DETECT | head -n1 | xargs | awk '{print $2,$3}')
# System & Graphics
NVIDIA_DRIVER=$(dpkg -l | grep nvidia-opencl-icd | grep ii | awk '{print $3}' | xargs | cut -d '-' -f 1)
if [ -z "$NVIDIA_DRIVER" ]; then
  NVIDIA_DRIVER=$(nvidia-smi | grep "Driver Version" | xargs | sed 's/[^0-9. ]*//g' | xargs | cut -d ' ' -f 1 | xargs)
fi
AMD_DRIVER=$(dpkg -l | grep vulkan-amdgpu-pro | head -n1 | awk '{print $3}' | xargs)
KERNEL_VERSION=$(uname -r)
UBUNTU_VERSION=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME="//g' | sed 's/"//g' | xargs)

while true
do

  echo "-*- BACKGROUND SERVICE -*-"

  RESPONSE="null"

  #HOSTNAME
  TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
  WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"

  echo ""
  echo "$TOKEN"
  echo "$WORKER"

  #FREE SPACE in Megabyte - SDA1
  STR1="$(df -hm | grep $DISK | awk '{print $4}')"

  echo "Free Space: $STR1"

  #CPU USAGE
  #STR2="$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')"
  STR2=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage ""}')

  echo "CPU Usage: $STR2"

  #REMOTE IP ADDRESS
  #STR4="$(wget -qO- http://ipecho.net/plain ; echo)"

  #LOCAL IP ADDRESS
  STR3="$(ifconfig | grep "inet" | grep -v "inet6" | grep -vE "127.0.0.1|169." | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | head -n 1 | grep -o -E '[.0-9]+')"
  echo "Local IP: $STR3"

  #FREE MEMORY
  STR5="$(free -m | grep 'Mem' | awk '{print $4}')"
  echo "Free Memory: $STR5"

  # TELEPROXY ID
  TELEID=$(sudo /home/minerstat/minerstat-os/bin/tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}' | cut -f1 -d"@" | sed 's/.* //')
  echo "TeleID: $TELEID"

  # SYSTEM UPTIME
  SYSTIME=$(awk '{print $1}' /proc/uptime | xargs)
  echo "SYS UPTIM: $SYSTIME"

  # MINER logs
  RAMLOG=$(cat /dev/shm/miner.log | tac | head --lines 10 | tac)
  echo "RAMLOG"

  # Extended Query with loop
  CPU_TEMP=$(cat /sys/class/thermal/thermal_zone*/temp | column -s $'\t' -t | sed 's/\(.\)..$/.\1/' | head -n 1)
  #CPU_USAGE=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage ""}')

  #echo "Remote IP: $STR4"
  echo ""

  IS_ONLINE="YES"
  echo "NETCHECK"

  while ! ping api.minerstat.com. -w 1 | grep "0%"; do
    OFFLINE_COUNT=$(($OFFLINE_COUNT + $OFFLINE_NUM))
    echo "$OFFLINE_COUNT"
    IS_ONLINE="NO"
    break
  done

  if [ "$IS_ONLINE" = "YES" ]; then

    OFFLINE_COUNT=0

    echo "online"

    #SEND INFO
    wget -qO- "https://api.minerstat.com:2053/v2/set_os_status.php?token=$TOKEN&worker=$WORKER&space=$STR1&cpu=$STR2&localip=$STR3&freemem=$STR5&teleid=$TELEID&systime=$SYSTIME&mobo=$MOBO_TYPE&bios=$BIOS_VERSION&msos=$MSOS_VERSION&mac=$MAC_ADDRESS&cputype=$CPU_TYPE&cpu_usage=$CPU_USAGE&cpu_temp=$CPU_TEMP&disk_type=$DISK_TYPE&nvidiad=$NVIDIA_DRIVER&amdd=$AMD_DRIVER&kernel=$KERNEL_VERSION&ubuntu=$UBUNTU_VERSION" ; echo

    echo "wget done"

    echo "-*- MINERSTAT LISTENER -*-"
    RESPONSE="$(wget -qO- "https://api.minerstat.com:2053/v2/os_listener.php?token=$TOKEN&worker=$WORKER" ; echo)"

    echo "RESPONSE: $RESPONSE"

  fi

  if [ "$IS_ONLINE" = "NO" ]; then
    echo "offline"
    if [ "$OFFLINE_COUNT" = "400" ]; then
      # Reboot after 10 min of connection lost
      RESPONSE="REBOOT"
    fi
  fi


  echo "response check"

  if [ $RESPONSE = "REBOOT" ]; then
    #sudo reboot -f
    #sudo su -c "echo 1 > /proc/sys/kernel/sysrq"
    #sudo su -c "echo b > /proc/sysrq-trigger"
    #sleep 2
    sudo reboot -f
  fi

  if [ $RESPONSE = "FORCEREBOOT" ]; then
    #sudo reboot -f
    sudo su -c "echo 1 > /proc/sys/kernel/sysrq"
    sudo su -c "echo b > /proc/sysrq-trigger"
    #sleep 2
    sudo reboot -f
  fi

  if [ $RESPONSE = "SHUTDOWN" ]; then
    #sudo shutdown -h now
    sudo su -c "echo 1 > /proc/sys/kernel/sysrq"
    sudo su -c "echo o > /proc/sysrq-trigger"
    sleep 2
    sudo shutdown -h now
  fi
  
  if [ $RESPONSE = "INSTANTOC" ]; then
    echo "-------------------------------------------"
    sudo /home/minerstat/minerstat-os/bin/overclock.sh instant
    echo "-------------------------------------------"
  fi

  if [ $RESPONSE = "CONSOLE" ]; then
    sudo su minerstat -c "sudo /bin/sh /home/minerstat/minerstat-os/core/rmate"
  fi

  if [ $RESPONSE = "RESTART" ] || [ $RESPONSE = "START" ] || [ $RESPONSE = "NODERESTART" ] || [ $RESPONSE = "RESTARTNODE" ]; then
    sudo su -c "sudo rm /tmp/stop.pid"
    sudo su -c "sudo screen -X -S minew quit"
    sudo su -c "sudo screen -X -S fakescreen quit"
    sudo su -c "screen -ls minew | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
    sudo su minerstat -c "screen -X -S fakescreen quit"
    sudo su minerstat -c "screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
    sudo killall node
    sudo su minerstat -c "screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh"
    sleep 2
    sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"
  fi

  if [ $RESPONSE = "STOP" ]; then
    echo "stop" > /tmp/stop.pid;
    sudo su -c "echo "" > /dev/shm/miner.log"
    sudo su -c "echo 'stop' > /tmp/stop.pid"
    sudo su minerstat -c "screen -X -S minerstat-console quit";
    sudo su -c "sudo screen -X -S minew quit"
    sudo node /home/minerstat/minerstat-os/stop.js
    sleep 2
    sudo su -c "sudo screen -X -S minew quit"
    sudo su minerstat -c "screen -X -S minerstat-console quit";
  fi

  #if [ $RESPONSE = "RECOVERY" ]; then
  #  cd /tmp; sudo screen -wipe; wget https://raw.githubusercontent.com/minerstat/minerstat-os/master/core/recovery.sh; sudo chmod 777 recovery.sh; nohup sh recovery.sh &
  #fi

  if [ $RESPONSE = "null" ]; then
    echo "No remote command pending..";
  fi

  echo "monitor logs"

  if [ "$MONITOR_TYPE" = "amd" ]; then
    AMDINFO=$(sudo /home/minerstat/minerstat-os/bin/amdinfo)
    QUERYPOWER=$(cd /home/minerstat/minerstat-os/bin/; sudo ./rocm-smi -P | grep 'Average Graphics Package Power:' | sed 's/.*://' | sed 's/W/''/g' | xargs)
    HWMEMORY=$(cd /home/minerstat/minerstat-os/bin/; cat amdmeminfo.txt)
    if [ -z "$HWMEMORY" ] || [ -f "/dev/shm/amdmeminfo.txt" ]; then
      HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
    fi
    HWSTRAPS=$(cd /home/minerstat/minerstat-os/bin/; sudo ./"$STRAPFILENAME" --current-minerstat)
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwType=amd" --data "hwData=$AMDINFO" --data "hwPower=$QUERYPOWER" --data "hwMemory=$HWMEMORY" --data "hwStrap=$HWSTRAPS" --data "mineLog=$RAMLOG" "https://api.minerstat.com:2053/v2/set_node_config_os.php"
  fi

  if [ "$MONITOR_TYPE" = "nvidia" ]; then
    QUERYNVIDIA=$(sudo /home/minerstat/minerstat-os/bin/gpuinfo nvidia)
    # NVIDIA DRIVER CRASH WATCHDOG
    TESTVIDIA=$(sudo nvidia-smi --query-gpu=count --format=csv,noheader | grep "lost")
    RAMLOG="$RAMLOG $TESTVIDIA"
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwType=nvidia" --data "hwData=$QUERYNVIDIA" --data "mineLog=$RAMLOG" "https://api.minerstat.com:2053/v2/set_node_config_os.php"

  fi

  sleep 20

done
