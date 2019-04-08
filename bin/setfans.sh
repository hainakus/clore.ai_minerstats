#!/bin/bash
exec 2>/dev/null

sudo rm dofans.sh
sleep 1

if [ ! $1 ]; then

  #################################£
  # Detect GPU's
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
  NVIDIA="$(nvidia-smi -L)"

  #################################£
  # Rig details
  TOKEN="$(cat /home/minerstat/minerstat-os/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g')"
  WORKER="$(cat /home/minerstat/minerstat-os/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g')"

  echo ""
  echo "-------- APPLY NEW FAN SETTINGS --------"

  echo ""
  echo "--- GRAPHICS CARDS ---"
  echo "FOUND AMD    :  $AMDDEVICE"
  echo "FOUND NVIDIA :  $NVIDIADEVICE"
  echo ""

  if [ ! -z "$NVIDIA" ]; then
    if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
      wget -qO dofans.sh "https://api.minerstat.com/v2/getfans.php?type=nvidia&token=$TOKEN&worker=$WORKER&nums=$NVIDIADEVICE"
      sleep 1
      sudo chmod 777 dofans.sh
      sleep 0.5
      sudo sh dofans.sh
    fi
  fi

  if [ "$AMDDEVICE" -gt "0" ]; then

    START_ID="$(sudo ./amdcovc | grep "Adapter" | cut -f1 -d':' | sed '1q' | sed 's/[^0-9]//g')"
    # First AMD GPU ID. 0 OR 1 Usually
    STARTS=$START_ID

    echo "STARTS WITH ID: $STARTS"

    i=0
    SKIP=""
    while [ $i -le $AMDDEVICE ]; do
      if [ -f "/sys/class/drm/card$i/device/pp_table" ]
      then
        SKIP=$SKIP
      else
        SKIP=$SKIP"-$i"
      fi
      i=$(($i+1))
    done

    if [ "$SKIP" != "" ]
    then
      echo "Integrated Graphics ID: "$SKIP
    fi

    wget -qO dofans.sh "https://api.minerstat.com/v2/getfans.php?type=amd&token=$TOKEN&worker=$WORKER&nums=$AMDDEVICE&starts=$STARTS&skip=$SKIP"
    sleep 1.5
    sudo chmod 777 dofans.sh
    sleep 0.5
    sudo sh dofans.sh
  fi

fi
