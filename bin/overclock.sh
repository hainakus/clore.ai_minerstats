#!/bin/bash
echo "*-*-* Overclocking in progress *-*-*"

INSTANT=$1

AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
if [ "$AMDDEVICE" = "0" ]; then
  AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
fi
NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
FORCE="no"

NVIDIA="$(nvidia-smi -L)"

if [ ! -z "$NVIDIA" ]; then
  if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
    DONVIDIA="YES"
  fi
fi

if [ "$AMDDEVICE" -gt "0" ]; then
  DOAMD="YES"
fi

echo "FOUND AMD: $AMDDEVICE || FOUND NVIDIA: $NVIDIADEVICE"
echo ""
echo ""
echo "--------------------------"

TOKEN="$(cat /home/minerstat/minerstat-os/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g')"
WORKER="$(cat /home/minerstat/minerstat-os/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g')"

echo "TOKEN: $TOKEN"
echo "WORKER: $WORKER"

echo "--------------------------"

sudo rm doclock.sh
sleep 1

if [ ! -z "$DONVIDIA" ]; then
  # Check XSERVER
  SNUMD=$(sudo su minerstat -c "screen -list | grep -c display")
  if [ "$SNUMD" = "0" ]; then
    sudo su minerstat -c "screen -A -m -d -S display sudo X"
  fi

  NVIDIA_FAN_NUM=$(sudo nvidia-settings -c :0 -q fans | grep "fan:" | wc -l)

  DUAL_FANS="no"

  if [ "$NVIDIA_FAN_NUM" != "$NVIDIADEVICE" ]; then
    echo "Nvidia: Some GPU may have dual fans."
    DUAL_FANS="yes"
  fi

   echo
   HOWMANYRTX=$(echo $NVIDIA | grep "RTX" | wc -l)
   HOWMANYGTX=$(echo $NVIDIA | grep "GTX" | wc -l)
   echo "RTX GPUs: ($HOWMANYRTX)"
   echo "GTX GPUs: ($HOWMANYGTX)"
   echo "Dual fans: $DUAL_FANS"
   RTXID=$(echo $NVIDIA | grep GPU | grep RTX | awk -F '\\:' '{print $1}' | sed 's/[^0-9]*//g' | xargs echo -n | xargs)
   GTXID=$(echo $NVIDIA | grep GPU | grep GTX | awk -F '\\:' '{print $1}' | sed 's/[^0-9]*//g' | xargs echo -n | xargs)
   echo "RTX ID's: $RTXID"
   echo "GTX ID's: $GTXID"
   echo

  sudo nvidia-smi -pm 1
  wget -qO doclock.sh "https://api.minerstat.com/v2/getclock.php?type=nvidia&token=$TOKEN&worker=$WORKER&nums=$NVIDIADEVICE&instant=$INSTANT"
  sleep 1.5
  sudo sh doclock.sh
  sync

  # NO IDEA, BUT THIS SOLVE P8 STATE ISSUES (ON ALL CARD!)
  sudo screen -A -m -d -S p8issue sudo sh /home/minerstat/minerstat-os/bin/p8issue.sh
  sleep 0.5

  sudo chvt 1
fi

if [ ! -z "$DOAMD" ]; then

  TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
  WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"
  HWMEMORY=$(cd /home/minerstat/minerstat-os/bin/; cat amdmeminfo.txt)
  if [ -z "$HWMEMORY" ] || [ -f "/dev/shm/amdmeminfo.txt" ]; then
    HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
  fi
  sudo chmod 777 /dev/shm/amdmeminfo.txt
  if [ ! -f "/dev/shm/amdmeminfo.txt" ]; then
    sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q | tac > /dev/shm/amdmeminfo.txt &
    sudo cp -rf /dev/shm/amdmeminfo.txt /home/minerstat/minerstat-os/bin
    sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
    HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
  fi
  sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwMemory=$HWMEMORY" "https://api.minerstat.com/v2/set_node_config_os.php"

  START_ID="$(sudo ./amdcovc | grep "Adapter" | cut -f1 -d':' | sed '1q' | sed 's/[^0-9]//g')"
  # First AMD GPU ID. 0 OR 1 Usually
  STARTS=$START_ID

  #FILE="/sys/class/drm/card0/device/pp_dpm_sclk"
  #if [ -f "$FILE" ]
  #then
  #	STARTS=0
  #else
  #	STARTS=1
  #fi


  echo "STARTS WITH ID: $STARTS"

  i=0
  SKIP=""
  while [ $i -le $AMDDEVICE ]; do
    if [ "$i" -lt "10" ]; then
      if [ -f "/sys/class/drm/card$i/device/pp_table" ]
      then
        SKIP=$SKIP
      else
        SKIP=$SKIP"-$i"
      fi
    fi
    i=$(($i+1))
  done

  if [ "$SKIP" != "" ]
  then
    echo "Integrated Graphics ID: "$SKIP
  fi

  sudo rm /media/storage/fans.txt
  sudo killall curve
  
  #isThisVega=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  #isThisVegaII=$(sudo /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  
  #sudo su minerstat -c "screen -X -S minerstat-console quit"; 
  #sudo su -c "sudo screen -X -S minew quit"; 
  #sudo su -c "echo "" > /dev/shm/miner.log";

  #if [ "$isThisVega" = "Vega" ] || [ "$isThisVegaII" = "VegaFrontierEdition" ]; then
    #sudo /home/minerstat/minerstat-os/core/autotune
  #fi

  wget -qO doclock.sh "https://api.minerstat.com/v2/getclock.php?type=amd&token=$TOKEN&worker=$WORKER&nums=$AMDDEVICE&instant=$INSTANT&starts=$STARTS"

  sleep 1.5
  sudo sh doclock.sh
  sync
  sudo chvt 1
fi
