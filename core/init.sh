#!/bin/bash

OFFLINE_COUNT=0
OFFLINE_NUM=40
IS_ONLINE="YES"
DETECT="$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g' | grep -v "sda3" | head -n1)"
PART=$DETECT"1"
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
  STR2="$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')"
  
  echo "CPU Usage: $STR2"

  #REMOTE IP ADDRESS
  #STR4="$(wget -qO- http://ipecho.net/plain ; echo)"

  #LOCAL IP ADDRESS
  STR3="$(ifconfig | grep "inet" | grep -v "inet6" | grep -v "127.0.0.1" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | head -n 1 | grep -o -E '[.0-9]+')"
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
    wget -qO- "https://api.minerstat.com/v2/set_os_status.php?token=$TOKEN&worker=$WORKER&space=$STR1&cpu=$STR2&localip=$STR3&freemem=$STR5&teleid=$TELEID&systime=$SYSTIME" ; echo

    echo "wget done"

    echo "-*- MINERSTAT LISTENER -*-"
    RESPONSE="$(wget -qO- "https://api.minerstat.com/v2/os_listener.php?token=$TOKEN&worker=$WORKER" ; echo)"

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

  if [ $RESPONSE = "CONSOLE" ]; then
    sudo su minerstat -c "sudo /bin/sh /home/minerstat/minerstat-os/core/rmate"
  fi

  if [ $RESPONSE = "RESTART" ] || [ $RESPONSE = "START" ] || [ $RESPONSE = "NODERESTART" ]; then
    sudo su -c "sudo screen -X -S minew quit"
    sudo su -c "sudo screen -X -S fakescreen quit"
    sudo su minerstat -c "screen -X -S fakescreen quit"
    screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh
    sleep 2
    screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh
  fi

  if [ $RESPONSE = "STOP" ]; then
    sudo su minerstat -c "screen -X -S minerstat-console quit"
    sudo su -c "sudo screen -X -S minew quit"
    sudo su -c "sudo screen -X -S fakescreen quit"
    sudo su minerstat -c "screen -X -S fakescreen quit"
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
    HWSTRAPS=$(cd /home/minerstat/minerstat-os/bin/; sudo ./"$STRAPFILENAME" --current-minerstat)
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwType=amd" --data "hwData=$AMDINFO" --data "hwPower=$QUERYPOWER" --data "hwMemory=$HWMEMORY" --data "hwStrap=$HWSTRAPS" --data "mineLog=$RAMLOG" "https://api.minerstat.com/v2/set_node_config_os.php"
  fi

  if [ "$MONITOR_TYPE" = "nvidia" ]; then
    QUERYNVIDIA=$(sudo /home/minerstat/minerstat-os/bin/gpuinfo nvidia)
    # NVIDIA DRIVER CRASH WATCHDOG
    TESTVIDIA=$(sudo nvidia-smi --query-gpu=count --format=csv,noheader | grep "lost")
    RAMLOG="$RAMLOG $TESTVIDIA"
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwType=nvidia" --data "hwData=$QUERYNVIDIA" --data "mineLog=$RAMLOG" "https://api.minerstat.com/v2/set_node_config_os.php"

  fi

  sleep 20

done
