#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_vega.sh 1 2 3 4 5 6"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = MVDD"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_vega.sh 0 945 1100 80 950 1070"
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
  MVDD=$6
  COREINDEX=$7
  version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`

  if [ -z "$COREINDEX" ]; then
    COREINDEX="7"
  fi

  if [ "$COREINDEX" = "skip" ]; then
    COREINDEX="7"
  fi

  echo "--**--**-- GPU $1 : VEGA 56/64 --**--**--"

  # Reset
  sudo bash -c "echo r > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

  # Requirements
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1_enable"
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 5 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode" # Compute Mode
  #sudo su -c "echo $COREINDEX > /sys/class/drm/card$GPUID/device/pp_mclk_od" # test

  # Core clock & VDDC

  if [ "$VDDC" = "0" ] || [ "$VDDC" = "skip" ] || [ -z "$VDDC" ]; then
    VDDC="1000" # DEFAULT FOR 1801Mhz @1114mV
  fi

  if [ "$MVDD" = "0" ] || [ "$MVDD" = "skip" ] || [ -z "$MVDD" ]; then
    MVDD="1070"
  fi


  # PP_TABLE MOD

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

  if [ "$MEMCLOCK" != "skip" ]; then
    mclk="MclkDependencyTable/entries/3/MemClk=$((MEMCLOCK*100))"
  fi

  TESTGFX=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get GfxclkDependencyTable/entries/7 2> /dev/null | grep -c "ERROR")
  if [ "$TESTGFX" -lt 1 ]; then
    gfx="GfxclkDependencyTable/entries/7=$VDDC GfxclkDependencyTable/entries/6=$VDDC GfxclkDependencyTable/entries/4=$VDDC"
  fi

  TESTMV=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get VddmemLookupTable/entries/0 2> /dev/null | grep -c "ERROR")
  if [[ "$TESTMV" -lt 1 ]]; then
    mvdd="VddmemLookupTable/entries/0=$MVDD"
  fi

  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 1 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 2 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 3 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 4 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 5 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 6 --vddc-table-set $VDDC
  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 7 --vddc-table-set $VDDC

  sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set \
    VddcLookupTable/entries/0=$VDDC VddcLookupTable/entries/1=$VDDC VddcLookupTable/entries/2=$VDDC VddcLookupTable/entries/3=$VDDC VddcLookupTable/entries/4=$VDDC VddcLookupTable/entries/5=$VDDC VddcLookupTable/entries/6=$VDDC VddcLookupTable/entries/7=$VDDC \
    MclkDependencyTable/entries/3/VddInd=4 $mclk $mvdd $gfx \
    StateArray/states/0/MemClockIndexLow=3 StateArray/states/0/MemClockIndexHigh=3 StateArray/states/1/MemClockIndexLow=3 StateArray/states/1/MemClockIndexHigh=3 StateArray/states/1/GfxClockIndexLow=7 \
    --write

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      echo "INFO: SETTING CORECLOCK : $CORECLOCK Mhz (STATE: $COREINDEX) @ $VDDC mV"

      sudo su -c "echo 's 1 $((CORECLOCK-10)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 2 $COREINDEX $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 3 $((CORECLOCK+20)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 4 $((CORECLOCK+30)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 5 $((CORECLOCK+40)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 6 $((CORECLOCK+50)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 7 $((CORECLOCK+60)) $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

      sudo su -c "echo 'vc 2 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    fi
  fi

  # Memory Clock

  if [ "$MEMCLOCK" != "skip" ]; then
    echo "INFO: SETTING MEMCLOCK : $MEMCLOCK Mhz"
    sudo su -c "echo 'm 2 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 'm 3 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
  fi

  # FANS (for safety) from Radeon VII solution
  for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
    if [ ! -z "$TEST" ]; then
      MAXFAN=$TEST
    fi
  done

  if [ "$FANSPEED" != 0 ]; then
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
  else
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
  fi

  for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_enable" 2>/dev/null
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1" 2>/dev/null # 70%
  done

  # FANS
  if [ "$FANSPEED" != 0 ]; then
    sudo ./rocm-smi -d $GPUID --setfan $FANSPEED"%"
  else
    sudo ./rocm-smi -d $GPUID --setfan 70%
  fi

  # comit
  sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
  sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

  # Apply
  sudo ./rocm-smi -d $GPUID --setsclk $COREINDEX
  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  # Check current states
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
  #sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info

  version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`
  if [ "$version" = "1.4.6" ] || [ "$version" = "1.5.2" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.5.3" ] || [ "$version" = "1.5.4" ] || [ "$version" = "1.5.5" ] || [ "$version" = "1.4.8" ]; then
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  fi

  # Safety
  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  # ECHO Changes
  echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  echo "-÷-*-****** MEM  CLOCKS *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  #screen -A -m -D -S soctimer sudo bash /home/minerstat/minerstat-os/bin/soctimer $GPUID &

  exit 1

fi