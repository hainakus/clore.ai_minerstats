#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_navi.sh 1 2 3 4 5 6"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = MVDD"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_navi.sh 0 930 1300 40 890 1000"
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
    COREINDEX="2"
  fi

  if [ "$COREINDEX" = "skip" ]; then
    COREINDEX="2"
  fi

  if [ "$COREINDEX" = "5" ]; then
    COREINDEX="2"
  fi

  if [ "$version" = "1.4" ] || [ "$version" = "1.4.5" ] || [ "$version" = "1.4.6" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.4.8" ] || [ "$version" = "1.5.3" ] || [ "$version" = "1.4.9" ] || [ "$version" = "1.5.2" ]; then
    if [ "$COREINDEX" = "1" ]; then
        COREINDEX="2"
    fi
  fi

  echo "--**--**-- GPU $1 : NAVI --**--**--"

  # Reset
  #sudo bash -c "echo r > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

  for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
    if [ ! -z "$TEST" ]; then
      MAXFAN=$TEST
    fi
  done

  # Requirements
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 5 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode"

  # CoreClock
  if [ "$VDDC" = "0" ] || [ "$VDDC" = "skip" ] || [ -z "$VDDC" ]; then
    VDDC="980"
  fi

  if [ "$MVDD" = "0" ] || [ "$MVDD" = "skip" ] || [ -z "$MVDD" ]; then
    MVDD="1000"
  fi

  # MemoryClock
  if [ "$MEMCLOCK" != "skip" ]; then
    sudo su -c "echo 'm 1 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    sudo su -c "echo 'm 2 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    sudo su -c "echo 'm 3 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
    # sudo su -c "echo 'm 1 $MEMCLOCK $MVDD' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    echo "GPU$GPUID : MEMCLOCK => $MEMCLOCK Mhz"

    sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_mclk_od"

    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    sudo su -c "echo 'c'> /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

  fi

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$VDDC" -lt "750" ]; then
        echo "Driver accept VDDC range until 800mV, you have set $VDDC and it got adjusted to 800mV"
        echo "You can set Core State 1 or Core State 2 for lower voltages"
        VDDC=800
      fi
      sudo su -c "echo 's 1 $CORECLOCK' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #sudo su -c "echo 'vc 1 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #sudo su -c "echo 'vc 1 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      sudo su -c "echo 'vc 2 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
      #sudo su -c "echo 'vc 3 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

      echo "GPU$GPUID : CORECLOCK => $CORECLOCK Mhz ($VDDC mV, state: $COREINDEX)"

      sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
      sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

      #sudo su -c "echo $COREINDEX > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"

    fi
  fi

  ###########################################################################
  if [ "$version" = "1.4" ] || [ "$version" = "1.4.5" ] || [ "$version" = "1.4.6" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.4.8" ]; then
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  fi
  #if [ "$version" = "1.5.3" ]; then
  #  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  #  sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  #fi
  ##########################################################################

  # Apply Changes
  sudo su -c "echo 'c'> /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

  # ECHO Changes
  echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  echo "-÷-*-****** MEM  CLOCKS *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  # FANS
  if [ "$FANSPEED" != 0 ]; then
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    FANVALUE=$(awk -v n="$FANVALUE" 'BEGIN{print int((n+5)/10) * 10}')
    echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
  else
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
  fi

  TESTD=$(timeout 5 dpkg -l | grep opencl-amdgpu-pro-icd | head -n1 | awk '{print $3}' | xargs | cut -f1 -d"-")
  
  if [ "$TESTD" != "20.30" ]; then
    echo "2" > /dev/shm/fantype.txt
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1_enable" 2>/dev/null
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1_enable" 2>/dev/null
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1" 2>/dev/null # 70%
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1" 2>/dev/null # 70%
  else
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1_enable" 2>/dev/null
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1" 2>/dev/null # 70%
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1_enable" 2>/dev/null
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1" 2>/dev/null # 70%
    sudo rm /dev/shm/fantype.txt 2>/dev/null
  fi

  if [ "$FANSPEED" = "100" ]; then
    echo "2" > /dev/shm/fantype.txt
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1_enable" 2>/dev/null
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1_enable" 2>/dev/null
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon?/pwm1" 2>/dev/null # 70%
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon??/pwm1" 2>/dev/null # 70%
  fi

  exit 1

fi
