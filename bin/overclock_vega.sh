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
  VDDCI=$8
  POWERLIMIT=$9
  SOC=${10}
  version=`cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g'`

  if [[ -z "$COREINDEX" ]] || [[ "$COREINDEX" = "skip" ]]; then
    COREINDEX="7"
  fi

  MAXFAN="255"

  if [ "$FANSPEED" != 0 ]; then
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE)"
  else
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE)"
  fi

  if [[ $FANVALUE -gt $MAXFAN ]]; then
    FANVALUE=$MAXFAN
  fi

  echo "--**--**-- GPU $1 : VEGA 56/64 --**--**--"

  # Requirements
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1_enable"
  sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
  sudo su -c "echo 5 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode" # Compute Mode


  # Core clock & VDDC
  if [ "$VDDC" = "0" ] || [ "$VDDC" = "skip" ] || [ -z "$VDDC" ]; then
    VDDC="1000" # DEFAULT FOR 1801Mhz @1114mV
  fi

  if [ "$MVDD" = "0" ] || [ "$MVDD" = "skip" ] || [ -z "$MVDD" ]; then
    MVDD="1070"
  fi

  # SoC Clock
  SOCMIN=600
  SOCMAX=1240

  if [ "$MEMCLOCK" != "skip" ]; then
    mclk="MclkDependencyTable/entries/3/MemClk=$((MEMCLOCK*100))"
  fi

  TESTMV=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get VddmemLookupTable/entries/0 2> /dev/null | grep -c "ERROR")
  if [[ "$TESTMV" -lt 1 ]]; then
    mvdd="VddmemLookupTable/entries/0=$MVDD"
  fi

  if [ "$CORECLOCK" != "skip" ]; then
    TESTCL=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get GfxclkDependencyTable/entries/7/Clk 2> /dev/null | grep -c "ERROR")
    if [[ "$TESTCL" -lt 1 ]]; then
      CCLK1=$((($CORECLOCK-5)*100))
      CCLK2=$((($CORECLOCK-4)*100))
      CCLK3=$((($CORECLOCK-3)*100))
      CCLK4=$((($CORECLOCK-2)*100))
      CCLK5=$((($CORECLOCK-1)*100))
      CCLK6=$((($CORECLOCK)*100))
      cclk="GfxclkDependencyTable/entries/7/Clk=$CCLK6 GfxclkDependencyTable/entries/6/Clk=$CCLK5 GfxclkDependencyTable/entries/5/Clk=$CCLK4 GfxclkDependencyTable/entries/4/Clk=$CCLK3 GfxclkDependencyTable/entries/3/Clk=$CCLK2 GfxclkDependencyTable/entries/2/Clk=$CCLK1"
    fi
  fi

  if [[ "$VDDCI" != "skip" ]] && [[ "$VDDCI" != "0" ]] && [[ "$VDDCI" != "" ]] && [ ! -z "$VDDCI" ]; then
    vddci="VddciLookupTable/entries/0/Vdd=$VDDCI"
  fi

  if [[ ! -z $SOC && $SOC != "0" && $SOC != "skip" ]]; then
    PARSED_SOC=$SOC
    if [[ $SOC -gt $SOCMAX ]]; then
      PARSED_SOC=980
      echo "SoC can't be higher than $SOCMAX using safe value 980"
    fi
    if [[ $SOC -lt $SOCMIN ]]; then
      PARSED_SOC=$SOCMIN
      # Ignore if set below limit
      echo "SOCCLK value ignored as below $SOCMIN Mhz limit"
    else
      PARSED_SOC=$((($PARSED_SOC)*100))
      psoc="SocclkDependencyTable/entries/0/Clk=$PARSED_SOC SocclkDependencyTable/entries/1/Clk=$PARSED_SOC SocclkDependencyTable/entries/2/Clk=$PARSED_SOC SocclkDependencyTable/entries/3/Clk=$PARSED_SOC SocclkDependencyTable/entries/4/Clk=$PARSED_SOC SocclkDependencyTable/entries/5/Clk=$PARSED_SOC SocclkDependencyTable/entries/6/Clk=$PARSED_SOC SocclkDependencyTable/entries/7/Clk=$PARSED_SOC StateArray/states/1/SocClockIndexHigh=7"
    fi
  fi

  timeout 10 sudo /home/minerstat/minerstat-os/bin/vegavolt -i $GPUID --volt-state 7 --vddc-table-set $VDDC

  sudo rm /dev/shm/safetycheck.txt &> /dev/null
  sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get StateArray/states/0/MemClockIndexLow &> /dev/shm/safetycheck.txt
  SAFETY=$(cat /dev/shm/safetycheck.txt)
  if [[ $SAFETY == *"has no attribute"* ]] || [[ $SAFETY == *"ModuleNotFoundError"* ]] || [[ $SAFETY == *"table version"* ]]; then
    sudo su minerstat -c "yes | sudo pip3 uninstall setuptools"
    sudo su minerstat -c "yes | sudo pip3 uninstall click"
    sudo su minerstat -c "yes | sudo pip3 uninstall upp"
    sudo su -c "yes | sudo pip3 uninstall upp"
    sudo su minerstat -c "pip3 install setuptools"
    sudo su minerstat -c "pip3 install git+https://labs.minerstat.farm/repo/upp"
    sudo su -c "pip3 install git+https://labs.minerstat.farm/repo/upp"
  fi

  # Radeon Pro Patch
  proArgs=""
  isRadeonPro=$(sudo timeout 20 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI ${11}:" | grep -E "Pro|PRO" | wc -l)

  if [[ "$isRadeonPro" -gt "0" ]]; then
    for (( i=0; i<=13; i+=1 )); do
      proArgs+="overdrive_table/cap/$i=1 "
    done
  fi

  sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set \
    VddcLookupTable/entries/0=$VDDC VddcLookupTable/entries/1=$VDDC VddcLookupTable/entries/2=$VDDC VddcLookupTable/entries/3=$VDDC VddcLookupTable/entries/4=$VDDC VddcLookupTable/entries/5=$VDDC VddcLookupTable/entries/6=$VDDC VddcLookupTable/entries/7=$VDDC \
    MclkDependencyTable/entries/3/VddInd=4 PowerTuneTable/SocketPowerLimit=300 PowerTuneTable/BatteryPowerLimit=300 PowerTuneTable/SmallPowerLimit=300 $vddci $cclk $mclk $mvdd $gfx $psoc \
    StateArray/states/0/MemClockIndexLow=3 StateArray/states/0/MemClockIndexHigh=3 StateArray/states/1/MemClockIndexLow=3 StateArray/states/1/MemClockIndexHigh=3 StateArray/states/1/GfxClockIndexLow=7 $proArgs \
    --write

  # Apply fans sysfs
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
  sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%

  # FANS failover rocm
  if [ "$FANSPEED" != 0 ]; then
    sudo ./rocm-smi -d $GPUID --setfan $FANSPEED"%"
  else
    sudo ./rocm-smi -d $GPUID --setfan 70%
  fi

  if [ "$VDDC" != "skip" ]; then
    if [ "$CORECLOCK" != "skip" ]; then
      echo "INFO: SETTING CORECLOCK : $CORECLOCK Mhz (STATE: $COREINDEX) @ $VDDC mV"

      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 1 $(($CORECLOCK-6)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 2 $(($CORECLOCK-5)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 3 $(($CORECLOCK-4)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 4 $(($CORECLOCK-3)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 5 $(($CORECLOCK-2)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 6 $(($CORECLOCK-1)) $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 7 $(($CORECLOCK)) $VDDC"

      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "vc 2 $CORECLOCK $VDDC"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"

      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo su -c "echo 7 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"

    fi
  fi

  # Memory Clock
  if [ "$MEMCLOCK" != "skip" ]; then
    echo "INFO: SETTING MEMCLOCK : $MEMCLOCK Mhz"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 2 $MEMCLOCK $MVDD"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "m 3 $MEMCLOCK $MVDD"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"
  fi

  # commit
  sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "c"
  sudo su -c "echo 'c' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

  # Apply
  sudo ./rocm-smi -d $GPUID --setsclk $COREINDEX
  sudo su -c "echo '2' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  sudo su -c "echo '7' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
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

  # fan
  sudo timeout 5 /home/minerstat/minerstat-os/bin/rocm-smi --setfan $FANVALUE -d $GPUID
  sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
  sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%

  # Apply powerlimit
  if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "skip" ]] && [[ "$POWERLIMIT" != "pwrskip" ]] && [[ "$POWERLIMIT" != "pwrSkip" ]] && [[ $POWERLIMIT == *"pwr"* ]]; then
    POWERLIMIT=$(echo $POWERLIMIT | sed 's/[^0-9]*//g')
    if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "0" ]]; then
      # Vega limits
      PW_MIN=$((85 * 1000000))
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

  TEST=$(screen -list | grep -wc soctimer)
  if [ "$TEST" = "0" ]; then
    screen -A -m -D -S soctimer sudo bash /home/minerstat/minerstat-os/bin/soctimer $GPUID &
    echo "#!/bin/bash" > /home/minerstat/clock_cache
    echo "sudo bash /home/minerstat/minerstat-os/bin/overclock_vega.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}" >> /home/minerstat/clock_cache
  else
    echo "sudo bash /home/minerstat/minerstat-os/bin/overclock_vega.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}" >> /home/minerstat/clock_cache
  fi

  exit 1

fi
