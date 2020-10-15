#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_amd.sh 1 2 3 4 5 6 7"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = VDDCI"
  echo "7 = MVDD"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_amd.sh 0 2100 1140 80 850 900 1000"
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
  MVDD=$7
  # GPU BUS ID TO INT
  GPUBUS=$8
  if [ ! -z $GPUBUS ]; then
    GPUBUSINT=$(echo $GPUBUS | cut -f 1 -d '.')
    GPUBUS=$(python -c 'print(int("'$GPUBUSINT'", 16))')
  fi
  # instant / normal
  INSTANT=$9
  # core state
  GPUINDEX=${10}

  if [ "$INSTANT" = "instant" ]; then
    echo "INSTANT OVERRIDE"
    echo "BUS => $8"
    if [ -f "/dev/shm/oc_old_$8.txt" ]; then
      echo
      echo "=== COMPARE VALUE FOUND ==="
      sudo cat /dev/shm/oc_old_$8.txt
      MEMCLOCK_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
      CORECLOCK_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
      FANSPEED_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
      VDDC_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "VDDC=" | xargs | sed 's/.*=//' | xargs)
      VDDCI_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "VDDCI=" | xargs | sed 's/.*=//' | xargs)
      MVDD_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "MVDD=" | xargs | sed 's/.*=//' | xargs)
      GPUBUS_OLD=$(cat /dev/shm/oc_old_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
      echo "==========="
      echo
    else
      MEMCLOCK_OLD="skip"
      CORECLOCK_OLD="skip"
      FANSPEED_OLD="skip"
      VDDC_OLD="skip"
      VDDCI_OLD="skip"
      MVDD_OLD="skip"
      GPUBUS_OLD=$(cat /dev/shm/oc_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
    fi
    echo "=== NEW VALUES FOUND ==="
    sudo cat /dev/shm/oc_$8.txt
    MEMCLOCK_NEW=$(cat /dev/shm/oc_$8.txt | grep "MEMCLOCK=" | xargs | sed 's/.*=//' | xargs)
    CORECLOCK_NEW=$(cat /dev/shm/oc_$8.txt | grep "CORECLOCK=" | xargs | sed 's/.*=//' | xargs)
    FANSPEED_NEW=$(cat /dev/shm/oc_$8.txt | grep "FAN=" | xargs | sed 's/.*=//' | xargs)
    VDDC_NEW=$(cat /dev/shm/oc_$8.txt | grep "VDDC=" | xargs | sed 's/.*=//' | xargs)
    VDDCI_NEW=$(cat /dev/shm/oc_$8.txt | grep "VDDCI=" | xargs | sed 's/.*=//' | xargs)
    MVDD_NEW=$(cat /dev/shm/oc_$8.txt | grep "MVDD=" | xargs | sed 's/.*=//' | xargs)
    GPUBUS_NEW=$(cat /dev/shm/oc_$8.txt | grep "BUS=" | xargs | sed 's/.*=//' | xargs)
    echo "==========="
    echo
    echo "=== COMPARE ==="
    ##################
    MEMCLOCK="skip"
    CORECLOCK="skip"
    FANSPEED="skip"
    VDDC="skip"
    VDDCI="skip"
    MVDD="skip"
    BUS=""
    ##################
    if [ "$MEMCLOCK_OLD" != "$MEMCLOCK_NEW" ]; then
      MEMCLOCK=$MEMCLOCK_NEW
    fi
    if [ "$CORECLOCK_OLD" != "$CORECLOCK_NEW" ]; then
      CORECLOCK=$CORECLOCK_NEW
    fi
    if [ "$FANSPEED_OLD" != "$FANSPEED_NEW" ]; then
      FANSPEED=$FANSPEED_NEW
    fi
    if [ "$VDDC_OLD" != "$VDDC_NEW" ]; then
      VDDC=$VDDC_NEW
    fi
    if [ "$VDDCI_OLD" != "$VDDCI_NEW" ]; then
      VDDCI=$VDDCI_NEW
    fi
    if [ "$MVDD_OLD" != "$MVDD_NEW" ]; then
      MVDD=$MVDD_NEW
    fi
    if [ "$GPUBUS_OLD" != "$GPUBUS_NEW" ]; then
      BUS=$GPUBUS_NEW
    fi
  fi

  ## BULIDING QUERIES
  STR1="";
  STR2="";
  R9="";

  # Check this is older R, or RX Series

  if [ ! -z $GPUBUS ]; then
    GID=$GPUBUS
    recheckID=$(ls /sys/bus/pci/devices/*$GPUBUSINT":00.0"/drm | grep "card" | sed 's/[^0-9]*//g')
    GPUID=$recheckID
  else
    GID=""
  fi

  echo "Checking GPU type.."

  isThisR9=$(sudo timeout 10 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "R9"| sed 's/^.*R9/R9/' | cut -f1 -d' ' | sed 's/[^A-Z0-9]*//g')
  isThisVega=$(sudo timeout 10 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaII=$(sudo timeout 10 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "Vega" | sed 's/^.*Vega/Vega/' | sed 's/[^a-zA-Z]*//g')
  isThisVegaVII=$(sudo timeout 10 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep "VII" | sed 's/^.*VII/VII/' | sed 's/[^a-zA-Z]*//g')
  isThisNavi=$(sudo timeout 10 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI $GID" | grep -E "5500|5550|5600|5650|5700|5750|5800|5850|5900|5950|6600|6700|6800|6900" | wc -l)

  ########## NAVI ##################
  if [ "$isThisNavi" -gt "0" ]; then
    echo "--**--**-- NAVI --**--**--"
    echo "Loading NAVI OC Script.."
    sudo ./overclock_navi.sh $GPUID $2 $3 $4 $5 $7 ${10} $6
    exit 1
  fi
  ################################

  ########## VEGA ##################
  if [ "$isThisVega" = "Vega" ]; then
    echo "--**--**-- VEGA --**--**--"
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  ########## VEGA VII ############
  if [ "$isThisVegaVII" = "VII" ]; then
    echo "--**--**-- VII --**--**--"
    echo "Loading VEGA VII OC Script.."
    sudo ./overclock_vega7.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  ########## BACKUP ##################
  if [ "$isThisVegaII" = "VegaFrontierEdition" ]; then
    echo "--**--**-- VEGA FRONTIER --**--**--"
    echo "Loading VEGA OC Script.."
    sudo ./overclock_vega.sh $GPUID $2 $3 $4 $5 $7 ${10}
    exit 1
  fi
  ################################

  if [ "$isThisR9" != "R9" ]; then
    if [ "$FANSPEED" != "skip" ]; then
      if [ "$FANSPEED" != 0 ]; then
        STR1="--set-fanspeed $FANSPEED";
        STR2="fanspeed:$GPUID=$FANSPEED";
      fi
    fi

    # Reset
    # sudo bash -c "echo r > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    if [ "$R9" != "" ]; then
      sudo ./amdcovc $R9 | grep "Setting"
    fi

    # Check Python3 PIP
    CHECKPY=$(dpkg -l | grep python3-pip)
    if [[ -z $CHECKPY ]]; then
      sudo apt-get update
      sudo apt-get -y install python3-pip --fix-missing
      sudo su minerstat -c "pip3 install upp"
    fi

    # Check UPP installed
    FILE=/home/minerstat/.local/bin/upp
    if [ -f "$FILE" ]; then
      echo "UPP exists."
    else
      sudo su minerstat -c "pip3 install upp"
    fi

    # Setting up limits
    MCMIN=750  #minimum vddci
    MCMAX=950  #max vddci
    MVMIN=750 #minimum mvdd
    MVMAX=1050 #max mvdd
    VDMIN=750 #min vdd
    VDMAX=1100 #max vdd

    # Compare user input and apply min/max
    if [[ ! -z $VDDCI && $VDDCI != "0" && $VDDCI != "skip" ]]; then
      PARSED_VDDCI=$VDDCI
      if [[ $VDDCI -gt $MCMAX ]]; then
        PARSED_VDDCI=$MCMAX
      fi
      if [[ $VDDCI -lt $MCMIN ]]; then
        PARSED_VDDCI=$MCMIN
      fi

      # fix
      TESTMD=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get MclkDependencyTable/entries/2/Vddci 2> /dev/null | grep -c "ERROR")
      if [[ "$TESTMD" -lt 1 ]]; then
        pvddci="MclkDependencyTable/entries/2/Vddci=$VDDCI "
      else
        pvddci="MclkDependencyTable/entries/1/Vddci=$VDDCI "
      fi
    fi

    if [[ ! -z $MVDD && $MVDD != "0" && $MVDD != "skip" ]]; then
      PARSED_MVDD=$MVDD
      if [[ $MVDD -gt $MVMAX ]]; then
        PARSED_MVDD=$MVMAX
      fi
      if [[ $MVDD -lt $MVMIN ]]; then
        PARSED_MVDD=$MVMIN
      fi

      # fix mvdd
      TESTMD=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get MclkDependencyTable/entries/2/Mvdd 2> /dev/null | grep -c "ERROR")
      if [[ "$TESTMD" -lt 1 ]]; then
        pmvdd="MclkDependencyTable/entries/2/Mvdd=$MVDD "
      else
        pmvdd="MclkDependencyTable/entries/1/Mvdd=$MVDD "
      fi
    fi

    if [ "$VDDC" != "skip" ] && [ "$VDDC" != "0" ]; then
      PARSED_VDD=$VDDC
      if [[ $VDDC -gt $VDMAX ]]; then
        PARSED_VDD=$VDMAX
      fi
      if [[ $VDDC -lt $VDMIN ]]; then
        PARSED_VDD=$VDMIN
      fi
      pvvdc="VddcLookupTable/entries/1/Vdd=$VDDC VddcLookupTable/entries/2/Vdd=$VDDC VddcLookupTable/entries/3/Vdd=$VDDC VddcLookupTable/entries/4/Vdd=$VDDC VddcLookupTable/entries/5/Vdd=$VDDC VddcLookupTable/entries/6/Vdd=$VDDC VddcLookupTable/entries/7/Vdd=$VDDC "
      pvvdc="$pvvdc VddcLookupTable/entries/8/Vdd=$VDDC VddcLookupTable/entries/9/Vdd=$VDDC VddcLookupTable/entries/10/Vdd=$VDDC VddcLookupTable/entries/11/Vdd=$VDDC VddcLookupTable/entries/12/Vdd=$VDDC VddcLookupTable/entries/13/Vdd=$VDDC VddcLookupTable/entries/14/Vdd=$VDDC "

      TESTMV=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get VddcLookupTable/entries/15/Vdd 2> /dev/null | grep -c "ERROR")
      if [[ "$TESTMV" -lt 1 ]]; then
        pvvdc="$pvvdc VddcLookupTable/entries/15/Vdd=$VDDC "
      fi
      TESTMV=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get VddgfxLookupTable/entries/7/Vdd 2> /dev/null | grep -c "ERROR")
      if [[ "$TESTMV" -lt 1 ]]; then
        pvvdc="$pvvdc VddgfxLookupTable/entries/7/Vdd=$VDDC"
      fi

      pvvdc="$pvvdc VddgfxLookupTable/entries/1/Vdd=$VDDC VddgfxLookupTable/entries/2/Vdd=$VDDC VddgfxLookupTable/entries/3/Vdd=$VDDC VddgfxLookupTable/entries/4/Vdd=$VDDC VddgfxLookupTable/entries/5/Vdd=$VDDC VddgfxLookupTable/entries/6/Vdd=$VDDC "
    fi

    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$CORECLOCK" != "0" ]; then
        CCLOCK=$((CORECLOCK*100))
        cclk="SclkDependencyTable/entries/2/Sclk=$CCLOCK SclkDependencyTable/entries/3/Sclk=$CCLOCK SclkDependencyTable/entries/4/Sclk=$CCLOCK SclkDependencyTable/entries/5/Sclk=$CCLOCK SclkDependencyTable/entries/6/Sclk=$CCLOCK SclkDependencyTable/entries/7/Sclk=$CCLOCK "
        cclk="$cclk SclkDependencyTable/entries/2/VddcOffset=0 SclkDependencyTable/entries/3/VddcOffset=0 SclkDependencyTable/entries/4/VddcOffset=0 SclkDependencyTable/entries/5/VddcOffset=0 SclkDependencyTable/entries/6/VddcOffset=0 SclkDependencyTable/entries/7/VddcOffset=0"
        cclk="$cclk SclkDependencyTable/entries/2/VddInd=7 SclkDependencyTable/entries/3/VddInd=7 SclkDependencyTable/entries/4/VddInd=7 SclkDependencyTable/entries/5/VddInd=7 SclkDependencyTable/entries/6/VddInd=7 SclkDependencyTable/entries/7/VddInd=7"
      fi
    fi

    if [ "$MEMCLOCK" != "skip" ]; then
      if [ "$MEMCLOCK" != "0" ]; then
        MCLK=$((MEMCLOCK*100))
        TESTMV=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get MclkDependencyTable/entries/2/Mclk 2> /dev/null | grep -c "ERROR")
        if [[ "$TESTMV" -lt 1 ]]; then
          pmclk="MclkDependencyTable/entries/2/Mclk=$MCLK "
        else
          pmclk="MclkDependencyTable/entries/1/Mclk=$MCLK "
        fi
      fi
    fi

    # Target temp
    FILE=/media/storage/fans.txt
    TT=59
    if [ -f "$FILE" ]; then
      TARGET=$(cat /media/storage/fans.txt | grep "TARGET_TEMP=" | xargs | sed 's/[^0-9]*//g')
      if [[ ! -z "$TARGET" ]]; then
        TT=$TARGET
        echo "Fan Curve Target: $TT"
      else
        TT=59
      fi
    else
      TT=59
    fi

    # Apply
    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set FanTable/TargetTemperature=$TT MaxODMemoryClock=230000 $cclk $pmclk $pvvdc $pmvdd $pvddci --write > /dev/shm/mclock_$GPUID.txt
    RBC=$(cat /dev/shm/mclock_$GPUID.txt)
    RBCE=$(cat /dev/shm/mclock_$GPUID.txt | grep -c "ERROR")
    echo "$RBC"

    SAFETY=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get MaxODMemoryClock)
    if [ -z "$SAFETY" ] || [ -z "$RBC" ] || [ "$RBCE" -gt 0 ]; then
      echo "UPP failed falling back to old method"

      maxMemState=$(sudo timeout 10 ./ohgodatool -i $GPUID --show-mem  | grep -E "Memory state ([0-9]+):" | tail -n 1 | sed -r 's/.*([0-9]+).*/\1/' | sed 's/[^0-9]*//g')
      if [ -z $currentCoreState ]; then
        echo "ERROR: No Current Core State found for GPU$GPUID"
        currentCoreState=5
      fi
      if [ "$currentCoreState" = 0 ]; then
        echo "WARN: GPU$GPUID was idle, using default states (5) (Idle)"
        currentCoreState=5
      fi
      if [ -z $maxMemState ]; then
        echo "ERROR: No Current Mem State found for GPU$GPUID"
        maxMemState=1;
      fi
      if [ "$VDDC" != "skip" ] && [ "$VDDC" != "0" ]; then
        echo "--- Setting up VDDC Voltage GPU$GPUID (VS: $currentVoltState) ---"
        for voltstate in 1 2 3 4 5 6 7; do
          sudo timeout 10 ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
        done
        for voltstate in 8 9 10 11 12 13 14 15; do
          sudo timeout 10 ./ohgodatool -i $GPUID --volt-state $voltstate --vddc-table-set $VDDC
        done
      fi
      if [ "$VDDCI" != "" ] && [ "$VDDCI" != "0" ] && [ "$VDDCI" != "skip" ]; then
        echo
        echo "--- Setting up VDDCI Voltage GPU$GPUID ---"
        echo
        if [ "$VDDCI" -gt "1000" ]; then
          echo "WARNING!!! HIGH VDDCI Voltage setting skipping to apply."
        else
          sudo timeout 10 ./ohgodatool -i $GPUID --mem-state $maxMemState --vddci $VDDCI
        fi
      fi
      if [ "$MVDD" != "" ] && [ "$MVDD" != "0" ] && [ "$MVDD" != "skip" ]; then
        echo
        echo "--- Setting up MVDD Voltage GPU$GPUID ---"
        echo
        if [ "$MVDD" -lt "1000" ]; then
          echo "WARNING!!! If you mining ETH keep memory voltages on 1000mv and try to reduce VDDC instead."
        fi
        if [ "$MVDD" -lt "950" ]; then
          #MVDD="950"
          echo "WARNING!! You have set lower MVDD than 950"
          echo "If mining not start 0H/s set MVDD back to 1000mV."
        fi
        sudo timeout 10 ./ohgodatool -i $GPUID --mem-state $maxMemState --mvdd $MVDD
      fi
      if [ "$CORECLOCK" != "skip" ]; then
        if [ "$CORECLOCK" != "0" ]; then
          STR5="coreclk:$GPUID=$CORECLOCK"
          if [ "$maxMemState" != "2" ]; then
            for corestate in 3 4 5 6 7 8; do
              sudo timeout 10 ./ohgodatool -i $GPUID --core-state $corestate --core-clock $CORECLOCK
            done
          else
            for corestate in 3 4 5 6 7 8; do
              sudo timeout 10 ./ohgodatool -i $GPUID --core-state $corestate --core-clock $CORECLOCK
            done
          fi
        fi
      fi
      if [ "$MEMCLOCK" != "skip" ]; then
        if [ "$MEMCLOCK" != "0" ]; then
          sudo timeout 10 ./ohgodatool -i $GPUID --mem-state $maxMemState --mem-clock $MEMCLOCK
        fi
      fi
      sudo su -c "echo $currentCoreState > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo $maxMemState > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    else
      echo "OK"
    fi

    sudo su -c "echo 'manual' > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
    sudo su -c "echo 3 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo 5 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo 7 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    sudo su -c "echo 3 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

    MAXFAN=255

    # FANS
    if [ "$FANSPEED" != 0 ]; then
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
    else
      FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
      FANVALUE=$(printf "%.0f\n" $FANVALUE)
      FANSPEED="70"
      echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
    fi

    sudo timeout 5 /home/minerstat/minerstat-os/bin/rocm-smi --setfan $FANVALUE -d $GPUID
    if [[ "$CORECLOCK" != "0" ]] && [[ "$CORECLOCK" != "skip" ]]; then
      sudo timeout 5 /home/minerstat/minerstat-os/bin/amdcovc coreclk:$GPUID=$CORECLOCK | grep "Setting"
    fi
    if [[ "$MEMCLOCK" != "0" ]] && [[ "$MEMCLOCK" != "skip" ]]; then
      sudo timeout 5 /home/minerstat/minerstat-os/bin/amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
    fi

    echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
    sudo su -c "timeout 3 cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk" | grep "*"
    echo "-÷-*-****** MEM  CLOCK *****-*-*÷-"
    sudo su -c "timeout 3 cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk" | grep "*"
    echo "-÷-*-******  VALIDATE RESULTS  *****-*-*÷-"
    sudo su -c "timeout 3 cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    echo "Keep in mind not all core and memory state listed upper. Only for feed back current values and ranges"
    echo ""
    exit 0

  else

    echo "== SETTING GPU$GPUID ==="

    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$CORECLOCK" != "0" ]; then
        sudo ./amdcovc coreclk:$GPUID=$CORECLOCK | grep "Setting"
      fi
    fi

    if [ "$MEMCLOCK" != "skip" ]; then
      if [ "$MEMCLOCK" != "0" ]; then
        sudo ./amdcovc memclk:$GPUID=$MEMCLOCK | grep "Setting"
        sudo ./amdcovc memod:$GPUID=20 | grep "Setting"
      fi
    fi

    if [ "$FANSPEED" != 0 ]; then
      sudo ./amdcovc fanspeed:$GPUID=$FANSPEED | grep "Setting"
    else
      sudo ./amdcovc fanspeed:$GPUID=70 | grep "Setting"
    fi

    if [ "$VDDC" != "skip" ]; then
      if [ "$VDDC" != "0" ]; then
        # Divide by 1000 to get mV in V
        VCORE=$(($VDDC / 1000))
        sudo ./amdcovc vcore:$GPUID=$VCORE | grep "Setting"
      fi
    fi

    echo ""

  fi

fi
