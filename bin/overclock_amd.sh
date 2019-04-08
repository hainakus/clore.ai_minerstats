#!/bin/bash
exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_amd.sh 1 2 3 4 5 6"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = VDDCI"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_amd.sh 0 2100 1140 80 850 900"
  echo ""
fi

if [ $1 ]; then

  #################################£
  # Declare
  GPUID=$1
  MEMCLOCK=$2
  CORECLOCK=$3
  FANSPEED=$4
  VDDC=$5
  VDDCI=$6
  # MDDC is not implemented due not effect much Polaris gpu's and..
  # really stable around 1000mV
  MDDC=$7

  ## BULIDING QUERIES
  STR1="";
  STR2="";
  STR3="";
  STR4="";
  STR5="";
  STR6="";
  OHGOD1="";
  OHGOD2="";
  OHGOD3="";
  OHGOD4="";
  R9="";

  # Check this is older R, or RX Series
  isThisR9=$(sudo ./amdcovc -a $1 | grep "R9"| sed 's/^.*R9/R9/' | cut -f1 -d' ' | sed 's/[^A-Z0-9]*//g')
  isThisVega=$(sudo ./amdcovc -a 0 | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaII=$(sudo ./amdcovc -a 0 | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaVII=$(sudo ./amdcovc -a 0 | grep "VII" | sed 's/^.*VII/VII/' | sed 's/[^a-zA-Z]*//g')

  ########## VEGA ##################
  if [ "$isThisVega" != "Vega" ]
  then
    echo ""
  else
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $1 $2 $3 $4 $5
    exit 1
  fi
  ################################

  ########## VEGA VII ############
  if [ "$isThisVegaVII" != "VII" ]
  then
    echo ""
  else
    echo "Loading VEGA VII OC Script.."
    sudo ./overclock_vega7.sh $1 $2 $3 $4 $5
    exit 1
  fi
  ################################

  ########## BACKUP ##################
  if [ "$isThisVegaII" != "AdapterPCIVegaXTXRadeonVegaFrontierEdition" ]
  then
    echo ""
  else
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $1 $2 $3 $4 $5
    exit 1
  fi
  ################################

  if [ "$isThisR9" != "R9" ]
  then

    if [ "$FANSPEED" != "skip" ]
    then
      if [ "$FANSPEED" != 0 ]
      then
        STR1="--set-fanspeed $FANSPEED";
        STR2="fanspeed:$GPUID=$FANSPEED";
      fi
    fi

    ## Detect state's
    maxMemState=$(sudo ./ohgodatool -i $GPUID --show-mem  | grep -E "Memory state ([0-9]+):" | tail -n 1 | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g')
    maxCoreState=$(sudo ./ohgodatool -i $GPUID --show-core | grep -E "DPM state ([0-9]+):"    | tail -n 1 | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g')
    currentCoreState=$(sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk | grep '*' | cut -f1 -d':' | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g'")
    #currentCoreState=5

    if [ "$R9" != "" ]
    then
      sudo ./amdcovc $R9 | grep "Setting"
    fi

    ## If $currentCoreState equals zero (undefined)
    ## Use maxCoreState BUT IF ZERO means idle use the same

    if [ -z $currentCoreState ]; then
      echo "ERROR: No Current Core State found for GPU$GPUID"
      currentCoreState=5
    fi

    if [ "$currentCoreState" != 0 ]
    then
      echo ""
    else
      echo "WARN: GPU$GPUID was idle, using default states (5) (Idle)"
      currentCoreState=5
    fi

    ## Memstate just for protection
    if [ -z $maxMemState ]; then
      echo "ERROR: No Current Mem State found for GPU$GPUID"
      $maxMemState = 1; # 1 is exist on RX400 & RX500 too.
    fi


    # CURRENT Volt State for Undervolt
    voltStateLine=$(($currentCoreState + 1))
    currentVoltState=$(sudo ./ohgodatool -i $GPUID --show-core | grep -E "VDDC:" | sed -n $voltStateLine"p" | sed 's/^.*entry/entry/' | sed 's/[^0-9]*//g')

    echo "DEBUG: C $currentCoreState / VL $voltStateLine / CVS $currentVoltState"
    echo ""

    if [ "$VDDC" != "skip" ]
    then
      if [ "$VDDC" != "0" ]
      then
        echo "--- Setting up VDDC Voltage GPU$GPUID (VS: $currentVoltState) ---"
        # set all voltage states from 1 upwards to xxx mV:
        #if [ "$maxMemState" != "2" ]
        #then
        #	sudo ./ohgodatool -i $GPUID --volt-state $currentVoltState --vddc-table-set $VDDC
        #else
        #	for voltstate in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        #		sudo ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
        #	done
        #fi
        for voltstate in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
          sudo ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
        done
      fi
    fi


    if [ "$VDDCI" != "" ]
    then
      if [ "$VDDCI" != "0" ]
      then
        if [ "$VDDCI" != "skip" ]
        then
          # VDDCI Voltages
          # VDDC Voltage + 50
          echo ""
          echo "--- Setting up VDDCI Voltage GPU$GPUID ---"
          sudo ./ohgodatool -i $GPUID --mem-state $maxMemState --vddci $VDDCI
        fi
      fi
    fi

    #################################£
    # SET MEMORY @ CORE CLOCKS

    if [ "$CORECLOCK" != "skip" ]
    then
      if [ "$CORECLOCK" != "0" ]
      then
        # APPLY AT THE END
        STR5="coreclk:$GPUID=$CORECLOCK"

        if [ "$maxMemState" != "2" ]
        then
          #OHGOD1=" --core-state $currentCoreState --core-clock $CORECLOCK"
          for corestate in 3 4 5 6 7 8; do
            sudo ./ohgodatool -i $GPUID --core-state $corestate --core-clock $CORECLOCK
          done
        else
          for corestate in 3 4 5 6 7 8; do
            sudo ./ohgodatool -i $GPUID --core-state $corestate --core-clock $CORECLOCK
          done
        fi

      fi
    fi


    if [ "$MEMCLOCK" != "skip" ]
    then
      if [ "$MEMCLOCK" != "0" ]
      then
        # APPLY AT THE END
        STR4="cmemclk:$GPUID=$MEMCLOCK"
        OHGOD2=" --mem-state $maxMemState --mem-clock $MEMCLOCK"
      fi
    fi

    #################################£
    # PROTECT FANS, JUST IN CASE
    if [ "$FANSPEED" != 0 ]
    then
      OHGOD3=" --set-fanspeed $FANSPEED"
      STR1="--set-fanspeed $FANSPEED"
      STR2="fanspeed:$GPUID=$FANSPEED"
    else
      OHGOD3=" --set-fanspeed 70"
      STR1="--set-fanspeed 70"
      STR2="fanspeed:$GPUID=70"
    fi

    if [ "$FANSPEED" != "skip" ]
    then
      echo ""
    else
      OHGOD3=" --set-fanspeed 70"
      STR1="--set-fanspeed 70"
      STR2="fanspeed:$GPUID=70"
    fi

    #################################£
    # Apply Changes
    #sudo ./amdcovc memclk:$GPUID=$MEMCLOCK cmemclk:$GPUID=$MEMCLOCK coreclk:$GPUID=$CORECLOCK ccoreclk:$GPUID=$CORECLOCK $STR2 | grep "Setting"
    #################################£
    # Overwrite PowerPlay to manual
    echo ""
    echo "--- APPLY CURRENT_CLOCKS ---"
    echo "- SET | GPU$GPUID Performance level: manual -"
    echo "- SET | GPU$GPUID DPM state: $currentCoreState -"
    echo "- SET | GPU$GPUID MEM state: $maxMemState -"
    sudo ./ohgodatool -i $GPUID $OHGOD1 $OHGOD2 $OHGOD3

    sudo su -c "echo 'manual' > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
    sudo su -c "echo $currentCoreState > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo $maxMemState > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    echo ""
    echo "NOTICE: If below is empty try to use a 'Supported clock or flash your gpu bios' "
    echo ""
    sleep 0.2
    sudo ./amdcovc $STR4 $STR5 $STR2 | grep "Setting"

    ##################################
    # CURRENT_Clock Protection
    sudo ./amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
    sudo ./amdcovc ccoreclk:$GPUID=$CORECLOCK | grep "Setting"

    # Fans for security
    for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
      if [ ! -z "$TEST" ]; then
        MAXFAN=$TEST
      fi
    done

    # FANS
    if [ "$FANSPEED" != 0 ]
    then
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
    else
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
    fi

    for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_enable"
      sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1" # 70%
    done

  else

    # R9 starts with 0 (zero)
    # Need new FUNC if GPU ID 1, apply to 0 too
    if [ "$GPUID" != "1" ]
    then
      echo "--------"
    else
      echo "-------- ID: 1 ---> Apply to ID: 0 also to make sure -----"
      sudo sh overclock_amd.sh 0 $MEMCLOCK $CORECOCK $FANSPEED $VDDC $VDDCI
    fi

    echo "== SETTING GPU$GPUID ==="

    if [ "$CORECLOCK" != "skip" ]
    then
      if [ "$CORECLOCK" != "0" ]
      then
        sudo ./amdcovc coreclk:$GPUID=$CORECLOCK | grep "Setting"
      fi
    fi

    if [ "$MEMCLOCK" != "skip" ]
    then
      if [ "$MEMCLOCK" != "0" ]
      then
        sudo ./amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
        sudo ./amdcovc memod:$GPUID=20 | grep "Setting"
      fi
    fi

    if [ "$FANSPEED" != 0 ]
    then
      sudo ./amdcovc fanspeed:$GPUID=$FANSPEED | grep "Setting"
    else
      sudo ./amdcovc fanspeed:$GPUID=70 | grep "Setting"
    fi

    if [ "$VDDC" != "skip" ]
    then
      if [ "$VDDC" != "0" ]
      then

        # Divide by 1000 to get mV in V
        VCORE=$(($VDDC / 1000))
        sudo ./amdcovc vcore:$GPUID=$VCORE | grep "Setting"

      fi
    fi

    echo ""

  fi

fi
