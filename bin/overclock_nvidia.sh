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
  echo "6 = Core Clock Lock"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_nvidia.sh 0 120 80 1300 100 1600"
  echo ""
fi

if [ $1 ]; then
  GPUID=$1
  POWERLIMITINWATT=$2
  FANSPEED=$3
  MEMORYOFFSET=$4
  COREOFFSET=$5
  # INSTANT
  INSTANT=$6
  # Lock core clock
  CORELOCK=$7
  # Lock memory clock
  MEMLOCK=$8

  ## BULIDING QUERIES
  STR1=""
  STR2=""
  STR3=""
  STR4="-c :0"

  if [ "$INSTANT" = "instant" ]; then
    echo "INSTANT OVERRIDE"
    echo "GPU ID => $1"
    if [ -f "/dev/shm/oc_old_$1.txt" ]; then
      echo
      echo "=== COMPARE VALUE FOUND ==="
      sudo cat /dev/shm/oc_old_$1.txt
      MEMORYOFFSET_OLD=$(cat /dev/shm/oc_old_$1.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
      COREOFFSET_OLD=$(cat /dev/shm/oc_old_$1.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
      FANSPEED_OLD=$(cat /dev/shm/oc_old_$1.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
      POWERLIMITINWATT_OLD=$(cat /dev/shm/oc_old_$1.txt | grep "POWERLIMIT=" | xargs | sed 's/.*=//' | xargs)
      echo "==========="
      echo
    else
      echo "=== COMPARE VALUE NOT FOUND ==="
      echo "USING SKIP EVERYWHERE"
      MEMORYOFFSET_OLD="skip"
      COREOFFSET_OLD="skip"
      FANSPEED_OLD="skip"
      POWERLIMITINWATT_OLD="skip"
      echo "==========="
    fi
    echo "=== NEW VALUES FOUND ==="
    sudo cat /dev/shm/oc_$1.txt
    MEMORYOFFSET_NEW=$(cat /dev/shm/oc_$1.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
    COREOFFSET_NEW=$(cat /dev/shm/oc_$1.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
    FANSPEED_NEW=$(cat /dev/shm/oc_$1.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
    POWERLIMITINWATT_NEW=$(cat /dev/shm/oc_$1.txt | grep "POWERLIMIT=" | xargs | sed 's/.*=//' | xargs)
    echo "==========="
    echo
    echo "=== COMPARE ==="
    ##################
    MEMORYOFFSET="skip"
    COREOFFSET="skip"
    FANSPEED="skip"
    POWERLIMITINWATT="skip"
    BUS=""
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

  # ClockTune Memory/Core Lock Delay
  # If 0 means disabled

  CLK_DELAY=$(cat /dev/shm/env_clk_delay.txt 2>/dev/null | xargs)

  echo "Env Clock Delay: $CLK_DELAY"

  if [[ "$CLK_DELAY" = "0" ]]; then
    INSTANT="instant"
  fi

  if [[ -z "$CLK_DELAY" ]]; then
    CLK_DELAY=40
  fi

  echo "Clock Delay: $CLK_DELAY, Instant: $INSTANT"

  # Write out to memory
  # echo $CLK_DELAY > /dev/shm/env_clk_delay.txt

  # DETECTING VIDEO CARD FOR PERFORMACE LEVEL

  QUERY="$(sudo nvidia-smi -i "$GPUID" --query-gpu=name --format=csv,noheader | tail -n1)"

  echo "--- GPU $GPUID: $QUERY ---";

  # DEFAULT IS 3 some card requires only different
  # This is obsolete method, just adding in case older driver versions
  # Since 400 series drivers, defining performance levels opciional
  PLEVEL=3

  if echo "$QUERY" | grep "1050" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P106-100" ;then PLEVEL=2
  elif echo "$QUERY" | grep "GTX 9" ;then PLEVEL=2
  elif echo "$QUERY" | grep "P102-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P104-100" ;then PLEVEL=1
  elif echo "$QUERY" | grep "P106-090" ;then PLEVEL=1
  elif echo "$QUERY" | grep "1660 SUPER" ;then PLEVEL=4
  elif echo "$QUERY" | grep "1650 SUPER" ;then PLEVEL=4
  elif echo "$QUERY" | grep "1660 Ti" ;then PLEVEL=4
  elif echo "$QUERY" | grep "RTX" ;then PLEVEL=4
  elif echo "$QUERY" | grep "1660" ;then PLEVEL=2
  elif echo "$QUERY" | grep "1650" ;then PLEVEL=2
  elif echo "$QUERY" | grep "CMP 30HX" ;then PLEVEL=2
  fi

  E1=""
  E2=""
  if [[ $QUERY == *"3070"* ]] || [[ $QUERY == *"3080"* ]] || [[ $QUERY == *"3090"* ]] || [[ $QUERY == *"3060"* ]] || [[ $QUERY == *"4060"* ]] || [[ $QUERY == *"4070"* ]] || [[ $QUERY == *"4080"* ]] || [[ $QUERY == *"4090"* ]]; then
    # GDDR6 fix
    MHZ=$((MEMORYOFFSET/2))
    EFF_MHZ=$(awk -v n=$MHZ 'BEGIN{print int((n+5)/10) * 10}')
    if [[ $MEMORYOFFSET -gt $EFF_MHZ ]]; then
      echo "Adjustment applied for memory clock"
      echo "Old memory offset $MEMORYOFFSET Mhz"
      MEMORYOFFSET=$((EFF_MHZ*2))
      echo "New memory offset $MEMORYOFFSET Mhz"
    fi

    # for instant OC just apply memclock without delay
    if [[ "$INSTANT" != "instant" ]]; then

      # DAG DELAY
      # SET MEMCLOCK BACK AFTER MINER STARTED 40 sec
      sudo echo "$GPUID:$MEMORYOFFSET" >> /dev/shm/nv_memcache.txt

      echo "!!!!!!!!"
      echo "GPU #$GPUID: $MEMORYOFFSET Mhz Memory Clock will be applied after miner started and DAG generated (40 sec)"
      echo "!!!!!!!"

      # DAG PROTECTION
      MEMORYOFFSET=0
      #COREOFFSET=0

      TEST=$(sudo screen -list | grep -wc memdelay)
      if [ "$TEST" = "0" ]; then
        sudo screen -A -m -d -S memdelay sudo bash /home/minerstat/minerstat-os/core/memdelay
      fi

    fi

    # P2
    E1="-a [gpu:"$GPUID"]/GPUMemoryTransferRateOffset[2]="$MEMORYOFFSET""
    E2="-a [gpu:"$GPUID"]/GPUGraphicsClockOffset[2]="$COREOFFSET""
  fi

  echo "--- PERFORMANCE LEVEL: $PLEVEL ---";

  #################################??
  # POWER LIMIT

  if [[ "$POWERLIMITINWATT" -ne 0 ]] && [[ "$POWERLIMITINWATT" != "skip" ]]; then
    sudo nvidia-smi -i $GPUID -pl $POWERLIMITINWATT
  fi

  #################################??
  # FAN SPEED

  if [[ "$FANSPEED" != "0" ]]; then
    echo "--- MANUAL GPU FAN MOD. ---"
  else
    echo "--- AUTO GPU FAN SPEED (by Drivers) ---"
    STR1="-a [gpu:$GPUID]/GPUFanControlState=0"
  fi

  if [[ "$FANSPEED" != "skip" ]]; then
    #STR1="-a GPUFanControlState=1 -a GPUTargetFanSpeed="$FANSPEED""
    sudo /home/minerstat/minerstat-os/core/nv_fanid $GPUID
    ID1=$(cat /dev/shm/id1.txt | xargs)
    ID2=$(cat /dev/shm/id2.txt | xargs)
    if [ -z "$ID1" ] && [ -z "$ID2" ]; then
      STR1="-a [gpu:"$GPUID"]/GPUFanControlState=1 -a [fan:"$GPUID"]/GPUTargetFanSpeed="$FANSPEED""
    else
      STR1="-a [gpu:"$GPUID"]/GPUFanControlState=1 -a [fan:"$ID1"]/GPUTargetFanSpeed="$FANSPEED""
      if [ ! -z "$ID2" ]; then
        STR1="$STR1 -a [gpu:"$GPUID"]/GPUFanControlState=1 -a [fan:"$ID2"]/GPUTargetFanSpeed="$FANSPEED""
      fi
    fi
  fi

  #################################??
  # CLOCKS

  if [[ "$MEMORYOFFSET" != "skip" ]] && [[ "$MEMORYOFFSET" != "0" ]]; then
    STR2="-a [gpu:"$GPUID"]/GPUMemoryTransferRateOffset["$PLEVEL"]="$MEMORYOFFSET" -a [gpu:"$GPUID"]/GPUMemoryTransferRateOffsetAllPerformanceLevels="$MEMORYOFFSET" $E1"
  fi

  if [[ "$COREOFFSET" != "skip" ]] && [[ "$COREOFFSET" != "0" ]]; then
    STR3="-a [gpu:"$GPUID"]/GPUGraphicsClockOffset["$PLEVEL"]="$COREOFFSET" -a [gpu:"$GPUID"]/GPUGraphicsClockOffsetAllPerformanceLevels="$COREOFFSET" $E2"
  fi

  # Lock core clock
  if [[ ! -z "$CORELOCK" ]] && [[ "$CORELOCK" != "0" ]] && [[ "$CORELOCK" != "skip" ]]; then
    echo "Applying Core Clock Lock to GPU $GPUID [$CORELOCK Mhz]"
    #STR3="-a [gpu:"$GPUID"]/GPUGraphicsClockOffset["$PLEVEL"]=0 -a [gpu:"$GPUID"]/GPUGraphicsClockOffsetAllPerformanceLevels=0 $E2"
    if [[ "$INSTANT" != "instant" ]]; then
      sudo echo "$GPUID:$CORELOCK" >> /dev/shm/nv_lockcache.txt
      # check lock delay process
      TEST=$(sudo screen -list | grep -wc lockdelay)
      if [ "$TEST" = "0" ]; then
        sudo screen -A -m -d -S lockdelay sudo bash /home/minerstat/minerstat-os/core/lockdelay &
      fi
    else
      sudo nvidia-smi -i $GPUID -lgc $CORELOCK
    fi
  fi

  # Lock memory clock
  if [[ ! -z "$MEMLOCK" ]] && [[ "$MEMLOCK" != "0" ]] && [[ "$MEMLOCK" != "skip" ]]; then
    echo "Applying Memory Clock Lock to GPU $GPUID [$MEMLOCK Mhz]"
    sudo nvidia-smi -i $GPUID -lmc $MEMLOCK
  else
    timeout 5 sudo nvidia-smi -i $GPUID -lmc  > /dev/null 2>&1
  fi

  #################################??
  # APPLY THIS GPU SETTINGS AT ONCE
  STR5="-a [gpu:"$GPUID"]/GPUPowerMizerMode=1"
  echo "$STR1 $STR2 $STR3 $STR5 " >> /dev/shm/nv_clkcache.txt
  DISPLAY=:0
  export DISPLAY=:0

fi
