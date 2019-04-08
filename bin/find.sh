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
else
  if [ "${RESULT:-null}" = null ]; then
    #################################£
    # Detect GPU's
    AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
    NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
    NVIDIA="$(nvidia-smi -L)"
    echo ""

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
        echo "GPU $1 >> 100%"
        STR2="-c :0 -a [gpu:$1]/GPUFanControlState=1 -a [gpu:$1]/GPUTargetFanSpeed=100"
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
      for gpuid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        sudo ./ohgodatool -i $gpuid --set-fanspeed 0 | grep "Fanspeed"
        sudo ./amdcovc fanspeed:$gpuid=0 | grep "Setting"
      done
      echo ""
      echo "-- AMD --"
      echo "DONE, WAIT 5 SEC."
      sleep 5
      echo ""
      echo "-- AMD --"
      echo "GPU $1 >> 100%"
      sudo ./ohgodatool -i $1 --set-fanspeed 100 | grep "Fanspeed"
      sudo ./amdcovc fanspeed:$1=100 | grep "Setting"
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
    echo "Then you are able to run again: mfind $1"
    echo "-----"
  fi

fi
