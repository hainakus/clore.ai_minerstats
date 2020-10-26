#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_navi.sh 1 2 3 4 5 6 7"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = MVDD"
  echo "7 = VDDCI"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_navi.sh 0 875 1300 70 800 1250 825"
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
  VDDCI=$8
  version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`

  # Setting up limits
  MCMIN=685  #minimum vddci
  MCMAX=850  #max vddci
  MVMIN=1250 #minimum mvdd
  MVMAX=1350 #max mvdd
  #MCDEF=820  #default vddci
  #MVDEF=1300 #default mvdd

  # Check Python3 PIP
  CHECKPY=$(dpkg -l | grep python3-pip)
  if [[ -z $CHECKPY ]]; then
    sudo apt-get update
    sudo apt-get -y install python3-pip --fix-missing
    sudo su minerstat -c "pip3 install setuptools"
    sudo su minerstat -c "pip3 install upp"
  fi

  # Check UPP installed
  FILE=/home/minerstat/.local/bin/upp
  if [ -f "$FILE" ]; then
    echo "UPP exists."
  else
    sudo su minerstat -c "pip3 install setuptools"
    sudo su minerstat -c "pip3 install upp"
  fi

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

  for fid in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    TEST=$(cat "/sys/class/drm/card$GPUID/device/hwmon/hwmon$fid/pwm1_max" 2>/dev/null)
    if [ ! -z "$TEST" ]; then
      MAXFAN=$TEST
    fi
  done

  echo "--**--**-- GPU $1 : NAVI --**--**--"

  # Compare user input and apply min/max
  if [[ ! -z $VDDCI && $VDDCI != "0" && $VDDCI != "skip" ]]; then
    PARSED_VDDCI=$VDDCI
    if [[ $VDDCI -gt $MCMAX ]]; then
      PARSED_VDDCI=$MCMAX
    fi
    if [[ $VDDCI -lt $MCMIN ]]; then
      PARSED_VDDCI=$MCMIN
      # Ignore if set below limit
      echo "VDDCI value ignored as below $MCMIN mV limit"
    else
      AVDDCI=$((PARSED_VDDCI * 4)) #actual
      pvddci="smc_pptable/MemVddciVoltage/2=$AVDDCI smc_pptable/MemVddciVoltage/3=$AVDDCI"
    fi
  fi

  if [[ ! -z $MVDD && $MVDD != "0" && $MVDD != "skip" ]]; then
    PARSED_MVDD=$MVDD
    if [[ $MVDD -gt $MVMAX ]]; then
      PARSED_MVDD=$MVMAX
    fi
    if [[ $MVDD -lt $MVMIN ]]; then
      PARSED_MVDD=$MVMIN
      # Ignore if set below limit
      echo "MVDD value ignored as below $MVMIN mV limit"
    else
      AMVDD=$((PARSED_MVDD * 4)) #actual
      pmvdd="smc_pptable/MemMvddVoltage/2=$AMVDD smc_pptable/MemMvddVoltage/3=$AMVDD"
    fi
  fi

  if [ "$version" = "1.5.4" ]; then
    echo "To enable PP_Table unlock flash to v1.6 or higher"
  else

    # Target temp
    FILE=/media/storage/fans.txt
    TT=50
    if [ -f "$FILE" ]; then
      TARGET=$(cat /media/storage/fans.txt | grep "TARGET_TEMP=" | xargs | sed 's/[^0-9]*//g')
      if [[ ! -z "$TARGET" ]]; then
        TT=$TARGET
        echo "NAVI Fan Curve Target: $TT"
      else
        TT=50
      fi
    else
      TT=50
    fi

    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set \
      overdrive_table/max/8=960 overdrive_table/min/3=700 overdrive_table/min/5=700 overdrive_table/min/7=700 smc_pptable/MinVoltageGfx=2800 \
      smc_pptable/FanTargetTemperature=$TT smc_pptable/FanThrottlingRpm=3000 $pmvdd $pvddci \
      smc_pptable/FanStopTemp=0 smc_pptable/FanStartTemp=0 smc_pptable/FanZeroRpmEnable=0 --write
  fi


  TESTD=$(timeout 5 dpkg -l | grep opencl-amdgpu-pro-icd | head -n1 | awk '{print $3}' | xargs | cut -f1 -d"-")

  if [ "$TESTD" != "20.30" || "$TESTD" != "20.40" ]; then
    echo "2" > /dev/shm/fantype.txt
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%
  else
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%
    sudo rm /dev/shm/fantype.txt 2>/dev/null
  fi

  if [ "$FANSPEED" = "100" ]; then
    echo "2" > /dev/shm/fantype.txt
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%
  fi

  # Requirements
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 5 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode"

  # CoreClock
  if [ "$VDDC" = "0" ] || [ "$VDDC" = "skip" ] || [ -z "$VDDC" ]; then
    VDDC="850"
  fi

  #if [ "$MVDD" = "0" ] || [ "$MVDD" = "skip" ] || [ -z "$MVDD" ]; then
  #  MVDD="1350"
  #fi

  # MemoryClock
  if [ "$MEMCLOCK" != "skip" ]; then
    if [[ $MEMCLOCK -gt "960" ]]; then
      echo "!! Invalid memory clock detected, auto fixing.."
      echo "Maximum possible clock atm 960Mhz (Windows: 960*2 = 1920Mhz)"
      echo "You have set $MEMCLOCK Mhz reducing back to 940Mhz"
      MEMCLOCK=940
    fi
    # Auto fix Windows Clocks to linux ones
    # Windows is memclock * 2
    if [[ $MEMCLOCK -gt "1500" ]]; then
      echo "!! MEMORY CLOCK CONVERTED TO LINUX FORMAT [WINDOWS_MEMCLOCK/2]"
      MEMCLOCK=$((MEMCLOCK/2))
    fi

    echo "GPU$GPUID : MEMCLOCK => $MEMCLOCK Mhz"

    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 1 $MEMCLOCK"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 2 $MEMCLOCK"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 3 $MEMCLOCK"

    sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_mclk_od"

    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"

  fi

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      if [ "$version" = "1.5.4" ]; then
        if [ "$VDDC" -lt "800" ]; then
          echo "Driver accept VDDC range until 800mV, you have set $VDDC and it got adjusted to 800mV"
          echo "You can set Core State 1 or Core State 2 for lower voltages or flash to v1.6 or higher where lowest possible value is 700mv"
          VDDC=800
        fi
      else
        if [ "$VDDC" -lt "700" ]; then
          echo "Driver accept VDDC range until 700mV, you have set $VDDC and it got adjusted to 800mV"
          echo "You can set Core State 1 or Core State 2 for lower voltages"
          VDDC=800
        fi
      fi

      echo "GPU$GPUID : CORECLOCK => $CORECLOCK Mhz ($VDDC mV, state: $COREINDEX)"

      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 1 $CORECLOCK"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "vc 2 $CORECLOCK $VDDC"

      sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
      sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

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
  sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"


  sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  sleep 0.25
  sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  # ECHO Changes
  echo "-÷-*-****** CORE CLOCK *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  echo "-÷-*-****** MEM  CLOCKS *****-*-*÷-"
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  exit 1

fi
