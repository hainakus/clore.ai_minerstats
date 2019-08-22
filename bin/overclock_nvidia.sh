#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_nvidia.sh 1 2 3 4 5"
  echo "1 = GPUID"
  echo "2 = POWER LIMIT in Watts (Example: 120 = 120W) [ROOT REQUIRED]"
  echo "3 = GLOBAL FAN SPEED (100 = 100%)"
  echo "4 = Memory Offset"
  echo "5 = Core Offset"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_nvidia.sh 0 120 80 1300 100"
  echo ""
fi

if [ $1 ]; then
  GPUID=$1
  POWERLIMITINWATT=$2
  FANSPEED=$3
  MEMORYOFFSET=$4
  COREOFFSET=$5

  ## BULIDING QUERIES
  STR1=""
  STR2=""
  STR3=""
  STR4="-c :0"

  # DETECTING VIDEO CARD FOR PERFORMACE LEVEL

  QUERY="$(sudo nvidia-smi -i "$GPUID" --query-gpu=name --format=csv,noheader | tail -n1)"

  echo "--- GPU $GPUID: $QUERY ---";

  # DEFAULT IS 3 some card requires only different
  PLEVEL=3

  if echo "$QUERY" | grep "1050" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P106-100" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P102-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P104-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P106-090" ;then PLEVEL=1
  elif echo "$QUERY" | grep "1660" ;then PLEVEL=4
  elif echo "$QUERY" | grep "RTX" ;then PLEVEL=4
  fi


  echo "--- PERFORMANCE LEVEL: $PLEVEL ---";

  #################################£
  # POWER LIMIT

  if [ "$POWERLIMITINWATT" != "skip" ]; then
    if [ "$POWERLIMITINWATT" -ne 0 ]; then
      sudo nvidia-smi -i $GPUID -pl $POWERLIMITINWATT
    fi
  fi

  #################################£
  # FAN SPEED

  if [ "$FANSPEED" != "0" ]
  then
    echo "--- MANUAL GPU FAN MOD. ---"
  else
    echo "--- AUTO GPU FAN SPEED (by Drivers) ---"
    STR1="-a [gpu:$GPUID]/GPUFanControlState=0"
  fi

  if [ "$FANSPEED" != "skip" ]
  then
    STR1="-a GPUFanControlState=1 -a GPUTargetFanSpeed="$FANSPEED""
    #STR1="-a [gpu:$GPUID]/GPUFanControlState=1 -a [fan:"$GPUID"]/GPUTargetFanSpeed="$FANSPEED""
    #edit=$((GPUID+1))
    #STR1="$STR1 -a [fan:"$edit"]/GPUTargetFanSpeed="$FANSPEED""
  fi

  #################################£
  # CLOCKS

  if [ "$MEMORYOFFSET" != "skip" ]
  then
    if [ "$MEMORYOFFSET" != "0" ]
    then
      STR2="-a [gpu:"$GPUID"]/GPUMemoryTransferRateOffset["$PLEVEL"]="$MEMORYOFFSET" -a [gpu:"$GPUID"]/GPUMemoryTransferRateOffsetAllPerformanceLevels="$MEMORYOFFSET""
    fi
  fi

  if [ "$COREOFFSET" != "skip" ]
  then
    if [ "$COREOFFSET" != "0" ]
    then
      STR3="-a [gpu:"$GPUID"]/GPUGraphicsClockOffset["$PLEVEL"]="$COREOFFSET" -a [gpu:"$GPUID"]/GPUGraphicsClockOffsetAllPerformanceLevels="$COREOFFSET""
    fi
  fi


  #################################£
  # APPLY THIS GPU SETTINGS AT ONCE
  FINISH="$(sudo nvidia-settings $STR1 $STR2 $STR3 $STR4)"
  echo $FINISH


fi
