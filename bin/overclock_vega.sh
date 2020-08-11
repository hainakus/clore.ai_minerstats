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

  if [ -z "$COREINDEX" ]; then
    COREINDEX="5"
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

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      echo "INFO: SETTING CORECLOCK : $CORECLOCK Mhz (STATE: $COREINDEX) @ $VDDC mV"
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 1 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 2 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 3 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 4 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 5 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 6 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 7 --vddc-table-set $VDDC
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --socclk-state 2 --socclk 1100
      timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --socclk-state 5 --socclk 1150

      sudo su -c "echo 's 0 852 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 1 853 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 2 854 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 3 855 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 4 856 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 5 857 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 6 858 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 7 859 $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's $COREINDEX $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --core-state $COREINDEX --core-clock $CORECLOCK

      sudo su -c "echo 'vc 2 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

      #sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
      #sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

      sudo su -c "echo $COREINDEX > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    fi
  fi

  # Memory Clock

  if [ "$MEMCLOCK" != "skip" ]; then
    echo "INFO: SETTING MEMCLOCK : $MEMCLOCK Mhz"
    #sudo su -c "echo 'm 1 $MEMCLOCK 1000' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    #sudo su -c "echo 'm 2 $MEMCLOCK 1050' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 'm 2 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 'm 3 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    #timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --mem-state 3 --mem-clock $MEMCLOCK
    sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    #sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    #sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    #sudo ./rocm-smi -d $GPUID --setmclk 3
    #timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --mem-state 3 --core-state $COREINDEX --mem-clock $MEMCLOCK --core-clock $CORECLOCK
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
  #sudo ./rocm-smi -d $GPUID --setmclk 3
  sudo su -c "echo '$COREINDEX' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  #sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk" # fix 167Mhz
  #sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  # Check current states
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
  #sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info

  version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`
  if [ "$version" = "1.4.6" ] || [ "$version" = "1.5.2" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.5.3" ] || [ "$version" = "1.5.4" ] || [ "$version" = "1.4.8" ]; then
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  fi

  # ECHO Changes
  echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  echo "-÷-*-****** MEM  CLOCKS *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  #sudo su -c "echo '$COREINDEX' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  #sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  screen -A -m -D -S soctimer sudo bash /home/minerstat/minerstat-os/bin/soctimer $GPUID &

  exit 1

fi
