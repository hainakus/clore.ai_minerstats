#!/bin/bash
exec 2>/dev/null

echo "---- FIND MY GPU ----"
echo ""

#################################£
# Check minerstat is running or not
RESULT=`pgrep node`

if [ ! $1 ]; then
  echo "Type your GPU ID what you want to find."
  echo "Example: mfind 0"
  echo "AMD Example with BUS Search: mfind 03.00.0"
else
  if [ "${RESULT:-null}" = null ]; then
    #################################£
    # Detect GPU's
    AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
    NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
    NVIDIA="$(nvidia-smi -L)"
    GID=$1
    echo ""
    sudo killall curve

    if [ ! -z "$NVIDIA" ]; then
      if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
        echo "NVIDIA: SET ALL FANS TO 0%"
        STR1="-c :0 -a GPUFanControlState=1 -a GPUTargetFanSpeed=0"
        FINISH="$(sudo nvidia-settings $STR1)"
        echo $FINISH
        echo ""
        echo "-- NVIDIA --"
        echo "DONE, WAIT 5 SEC."
        sleep 5
        echo ""
        echo "-- NVIDIA --"
        echo "GPU $GID >> 100%"
        STR2="-c :0 -a [gpu:$GID]/GPUFanControlState=1 -a [gpu:$GID]/GPUTargetFanSpeed=100"
        APPLY="$(sudo nvidia-settings $STR2)"
        echo $APPLY
        echo ""
        echo "-- NVIDIA --"
        echo "DONE, WAIT 5 SEC."
        sleep 5
        echo ""
        echo "--- Loading original settings --"
        cd /home/minerstat/minerstat-os/bin
        sudo sh setfans.sh
      fi
    fi

    if [ "$AMDDEVICE" -gt "0" ]; then
      echo ""
      echo "-- STATUS --"
      echo "AMD: SET ALL FANS TO 0%"
      sudo /home/minerstat/minerstat-os/bin/gpuinfo amd
      echo ""
      if [ ${#GID} -ge 3 ]; then
        echo "-- VALIDATE ON BUS --"
        GPUBUSINT=$(echo $GPUBUS | cut -f 1 -d '.')
        GPUBUS=$(python -c 'print(int("'$GPUBUSINT'", 16))')
        echo "Bus ID: $GID"
        GID=$(ls /sys/bus/pci/devices/*$GPUBUSINT":00.0"/drm | grep "card" | sed 's/[^0-9]*//g')
        echo "Rechecked ID: $GID"
      fi
      sudo /home/minerstat/minerstat-os/bin/rocm-smi --setfan 0
      echo ""
      echo "-- AMD --"
      echo "DONE, WAIT 5 SEC."
      sleep 5
      echo ""
      echo "-- AMD --"
      echo "GPU $GID >> 200 RPM"
      sudo /home/minerstat/minerstat-os/bin/rocm-smi --setfan 200 -d $GID
      echo ""
      echo "-- AMD --"
      echo "DONE, WAIT 3 SEC."
      sleep 5
      echo ""
      echo "--- Loading original settings --"
      cd /home/minerstat/minerstat-os/bin
      sudo sh setfans.sh
    fi

  else

    echo "-----"
    echo "You need to stop running miner before you can use this script."
    echo "Type: mstop"
    echo "Then you are able to run again: mfind $GID"
    echo "-----"
  fi

fi
