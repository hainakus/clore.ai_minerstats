#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_vega7.sh 1 2 3 4 5 6"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = MVDD"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_vega7.sh 0 1000 1800 90 980"
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
  POWERLIMIT=$8

  if [ -z "$COREINDEX" ]; then
    COREINDEX="7"
  fi

  if [ "$COREINDEX" = "skip" ]; then
    COREINDEX="7"
  fi

  echo "--**--**-- GPU $1 : VEGA VII --**--**--"

  # Enable overdrive
  # Radeon Pro Patch
  proArgs=""
  isRadeonPro=$(sudo timeout 20 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI ${11}:" | grep -E "Pro|PRO" | wc -l)

  if [[ "$isRadeonPro" -gt "0" ]]; then
    for (( i=0; i<=13; i+=1 )); do
      proArgs+="overdrive_table/cap/$i=1 "
    done
    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set $proArgs --write
  fi

  # FANS
  MAXFAN="255"
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

  if [[ $FANVALUE -gt $MAXFAN ]]; then
    FANVALUE=$MAXFAN
  fi

  # Requirements
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 6 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode"

  # CoreClock
  if [ "$VDDC" = "0" ] || [ "$VDDC" = "skip" ] || [ -z "$VDDC" ]; then
    VDDC="1114" # DEFAULT FOR 1801Mhz @1114mV
  fi

  if [ "$MVDD" = "0" ] || [ "$MVDD" = "skip" ] || [ -z "$MVDD" ]; then
    MVDD="1070"
  fi

  # MemoryClock
  if [ "$MEMCLOCK" != "skip" ]; then
    echo "GPU$GPUID : MEMCLOCK => $MEMCLOCK Mhz"

    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 1 $MEMCLOCK"

    sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

  fi

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      echo "GPU$GPUID : CORECLOCK => $CORECLOCK Mhz ($VDDC mV, state: $COREINDEX)"

      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 1 $CORECLOCK"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "vc 2 $CORECLOCK $VDDC"

      sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
      sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

      sudo su -c "echo 7 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 8 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"

    fi
  fi

  # Commit
  sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"
  sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

  # Apply powerlimit
  if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "skip" ]] && [[ "$POWERLIMIT" != "pwrskip" ]] && [[ "$POWERLIMIT" != "pwrSkip" ]] && [[ $POWERLIMIT == *"pwr"* ]]; then
    POWERLIMIT=$(echo $POWERLIMIT | sed 's/[^0-9]*//g')
    if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "0" ]]; then
      # VII limits
      PW_MIN=$((150 * 1000000))
      PW_MAX=$((350 * 1000000))
      # CONVERT
      CNV=$(($POWERLIMIT * 1000000))
      if [[ $CNV -lt $PW_MIN ]]; then
        echo "ERROR: New power limit not set, because less than allowed minimum $PW_MIN"
      else
        if [[ $CNV -lt $PW_MAX ]]; then
          FROM=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/power1_cap)
          echo "Changing power limit from $FROM W to $CNV W"
          sudo su -c "echo $CNV > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/power1_cap"
        else
          echo "ERROR: New power limit not set, because more than allowed maximum $PW_MAX"
        fi
      fi
    fi
  fi

  # Apply
  sudo ./rocm-smi -d $GPUID --setsclk 7
  sudo ./rocm-smi -d $GPUID --setsclk 8
  sudo ./rocm-smi -d $GPUID --setmclk 1
  sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  # Check current states
  sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

  # Apply fans via sysfs
  sudo timeout 5 /home/minerstat/minerstat-os/bin/rocm-smi --setfan $FANVALUE -d $GPUID
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
  sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%

  exit 1

fi
