#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_nvidia_all.sh 1 2 3 4"
  echo "1 = POWER LIMIT in Watts (Example: 120 = 120W) [ROOT REQUIRED]"
  echo "2 = GLOBAL FAN SPEED (100 = 100%)"
  echo "3 = Memory Offset"
  echo "4 = Core Offset"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_nvidia_all.sh 0 120 80 1300 100"
  echo ""
fi

if [ $1 ]; then
  POWERLIMITINWATT=$1
  FANSPEED=$2
  MEMORYOFFSET=$3
  COREOFFSET=$4

  ## BULIDING QUERIES
  STR1=""
  STR2=""
  STR3=""
  STR4="-c :0"

  # INSTANT
  INSTANT=$5

  if [ "$INSTANT" = "instant" ]; then
    echo "INSTANT OVERRIDE"
    echo "GPU ID => ALL"
    if [ -f "/dev/shm/oc_old_all.txt" ]; then
      echo
      echo "=== COMPARE VALUE FOUND ==="
      sudo cat /dev/shm/oc_old_all.txt
      MEMORYOFFSET_OLD=$(cat /dev/shm/oc_old_all.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
      COREOFFSET_OLD=$(cat /dev/shm/oc_old_all.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
      FANSPEED_OLD=$(cat /dev/shm/oc_old_all.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
      POWERLIMITINWATT_OLD=$(cat /dev/shm/oc_old_all.txt | grep "POWERLIMIT=" | xargs | sed 's/.*=//' | xargs)
      echo "==========="
      echo
    fi
    if [ ! -f "/dev/shm/oc_old_all.txt" ]; then
      echo "=== COMPARE VALUE NOT FOUND ==="
      echo "USING SKIP EVERYWHERE"
      MEMORYOFFSET_OLD="skip"
      COREOFFSET_OLD="skip"
      FANSPEED_OLD="skip"
      POWERLIMITINWATT_OLD="skip"
      echo "==========="
    fi
    echo "=== NEW VALUES FOUND ==="
    sudo cat /dev/shm/oc_all.txt
    MEMORYOFFSET_NEW=$(cat /dev/shm/oc_all.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
    COREOFFSET_NEW=$(cat /dev/shm/oc_all.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
    FANSPEED_NEW=$(cat /dev/shm/oc_all.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
    POWERLIMITINWATT_NEW=$(cat /dev/shm/oc_all.txt | grep "POWERLIMIT=" | xargs | sed 's/.*=//' | xargs)
    echo "==========="
    echo
    echo "=== COMPARE ==="
    ##################
    MEMORYOFFSET="skip"
    COREOFFSET="skip"
    FANSPEED="skip"
    POWERLIMITINWATT="skip"
    ##################
    if [ "$MEMORYOFFSET_OLD" != "$MEMORYOFFSET_NEW" ]; then
      MEMORYOFFSET=$MEMORYOFFSET_NEW
    fi
    if [ "$COREOFFSET_OLD" != "$COREOFFSET_NEW" ]; then
      COREOFFSET=$COREOFFSET_NEW
    fi
    if [ "$FANSPEED_OLD" != "$FANSPEED_NEW" ]; then
      FANSPEED=$FANSPEED_NEW
    fi
    if [ "$POWERLIMITINWATT_OLD" != "$POWERLIMITINWATT_NEW" ]; then
      POWERLIMITINWATT=$POWERLIMITINWATT_NEW
    fi
  fi

  # DETECTING VIDEO CARD FOR PERFORMACE LEVEL

  QUERY="$(sudo nvidia-smi -i 0 --query-gpu=name --format=csv,noheader | tail -n1)"

  echo "--- GPU $GPUID: $QUERY ---";

  # DEFAULT IS 3 some card requires only different
  PLEVEL=3

  if echo "$QUERY" | grep "1050" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P106-100" ;then PLEVEL=2
  elif echo "$QUERY" | grep "GTX 9" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P102-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P104-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P106-090" ;then PLEVEL=1
  elif echo "$QUERY" | grep "1660 SUPER" ;then PLEVEL=4
  elif echo "$QUERY" | grep "1660 Ti" ;then PLEVEL=4
  elif echo "$QUERY" | grep "RTX" ;then PLEVEL=4
  elif echo "$QUERY" | grep "1660" ;then PLEVEL=2
  elif echo "$QUERY" | grep "1650" ;then PLEVEL=2
  fi


  echo "--- PERFORMANCE LEVEL: $PLEVEL ---";
  
  sudo nvidia-smi -pm 1

  #################################£
  # POWER LIMIT

  if [ "$POWERLIMITINWATT" -ne 0 ]
  then
    if [ "$POWERLIMITINWATT" != "skip" ]
    then
      sudo nvidia-smi -pl $POWERLIMITINWATT
    fi
  fi

  #################################£
  # FAN SPEED

  if [ "$FANSPEED" != "0" ]
  then
    echo "--- MANUAL GPU FAN MOD. ---"
  else
    echo "--- AUTO FAN SPEED (by Drivers) ---"
    STR1="-a GPUFanControlState=0"
  fi

  if [ "$FANSPEED" != "skip" ]
  then
    STR1="-a GPUFanControlState=1 -a GPUTargetFanSpeed="$FANSPEED""
  fi

  #################################£
  # CLOCKS

  if [ "$MEMORYOFFSET" != "skip" ]
  then
    if [ "$MEMORYOFFSET" != "0" ]
    then
      STR2="-a GPUMemoryTransferRateOffset["$PLEVEL"]="$MEMORYOFFSET" -a GPUMemoryTransferRateOffsetAllPerformanceLevels="$MEMORYOFFSET""
    fi
  fi

  if [ "$COREOFFSET" != "skip" ]
  then
    if [ "$COREOFFSET" != "0" ]
    then
      STR3="-a GPUGraphicsClockOffset["$PLEVEL"]="$COREOFFSET" -a GPUGraphicsClockOffsetAllPerformanceLevels="$COREOFFSET""
    fi
  fi


  #################################£
  # APPLY THIS GPU SETTINGS AT ONCE
  echo "$STR1 $STR2 $STR3 $STR4"
  STR5="-a GPUPowerMizerMode=1"
  FINISH="$(sudo nvidia-settings -c :0 $STR1 $STR2 $STR3 $STR5)"
  echo $FINISH

  sleep 2
  sudo chvt 1

fi
