#!/bin/bash
echo "*-*-* Overclocking in progress *-*-*"

BIOS=$1

AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
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

if [ "$BIOS" != "" ]
then
  echo "Overwritting BIOS, Notice this requires a reboot (mreboot)"
  FORCE="yes"
fi

if [ ! -z "$DONVIDIA" ]; then
  sudo nvidia-smi -pm 1
  wget -qO doclock.sh "https://api.minerstat.com/v2/getclock.php?type=nvidia&token=$TOKEN&worker=$WORKER&nums=$NVIDIADEVICE&bios=$FORCE"
  sleep 1.5
  sudo sh doclock.sh
  sync

  # NO IDEA, BUT THIS SOLVE P8 STATE ISSUES (ON ALL CARD!)
  sudo screen -A -m -d -S p8issue sudo sh /home/minerstat/minerstat-os/bin/p8issue.sh
  sleep 0.5

  sudo chvt 1
fi

if [ ! -z "$DOAMD" ]; then

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

  wget -qO doclock.sh "https://api.minerstat.com/v2/getclock.php?type=amd&token=$TOKEN&worker=$WORKER&nums=$AMDDEVICE&bios=$FORCE&starts=$STARTS&skip=$SKIP"
  sleep 1.5
  sudo sh doclock.sh
  sync
  sudo chvt 1
fi
