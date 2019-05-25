#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_vega.sh 1 2 3 4 5"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_vega.sh 0 945 1100 80 950"
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

  echo "--**--**-- GPU $1 : VEGA 56/64 --**--**--"

  # Requirements
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1_enable"
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 4 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode" # Compute Mode

  # Core clock & VDDC

  if [ "$VDDC" != "0" ]
  then
    echo ""
  else
    VDDC="1000" # DEFAULT FOR 1630Mhz @1200mV
  fi

  if [ "$VDDC" != "skip" ]
  then
    if [ "$CORECLOCK" != "skip" ]
    then
      echo "INFO: SETTING CORECLOCK : $CORECLOCK Mhz @ $VDDC mV"
      #sudo su -c "echo 's 5 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #sudo su -c "echo 's 6 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 's 7 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      # NITRO has 8 core state ?!
      sudo su -c "echo 's 8 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/pp_sclk_od"
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_sclk_od"
    fi
  fi

  # Memory Clock

  if [ "$MEMCLOCK" != "skip" ]
  then
    echo "INFO: SETTING MEMCLOCK : $MEMCLOCK Mhz"
    #sudo su -c "echo 'm 1 $MEMCLOCK 1000' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    #sudo su -c "echo 'm 2 $MEMCLOCK 1050' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 'm 3 $MEMCLOCK 1070' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage" # @ 1100 mV default
    sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo ./rocm-smi --setmclk 3
  fi

  # FANS (for safety) from Radeon VII solution
  for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
    if [ ! -z "$TEST" ]; then
      MAXFAN=$TEST
    fi
  done

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
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_enable" 2>/dev/null
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1" 2>/dev/null # 70%
  done

  # FANS
  if [ "$FANSPEED" != 0 ]
  then
    sudo ./rocm-smi --setfan $FANSPEED"%"
  else
    sudo ./rocm-smi --setfan 70%
  fi

  # Apply
  sudo ./rocm-smi --setsclk 7
  sudo ./rocm-smi --setmclk 3
  # Check current states
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
  #sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info

  exit 1

fi
