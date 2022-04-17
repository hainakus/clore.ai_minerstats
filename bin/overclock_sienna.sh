#!/bin/bash
#exec 2>/dev/null

if [ ! $1 ]; then
  echo ""
  echo "--- EXAMPLE ---"
  echo "./overclock_sienna.sh 1 2 3 4 5 6 7"
  echo "1 = GPUID"
  echo "2 = Memory Clock"
  echo "3 = Core Clock"
  echo "4 = Fan Speed"
  echo "5 = VDDC"
  echo "6 = MVDD"
  echo "7 = VDDCI"
  echo ""
  echo "-- Full Example --"
  echo "./overclock_sienna.sh 0 1000 1400 80 900 1350 825"
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
  # ID 11 is for GPUID PRO
  SOCVDD=${12}
  TDCMAX=${13}

  version=$(cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^.0-9]*//g')
  version_r=$(cat /etc/lsb-release | grep "DISTRIB_RELEASE=" | sed 's/[^0-9]*//g')

  # Setting up limits
  MCMIN=600  #minimum vddci
  MCMAX=850  #max vddci
  MVMIN=1250 #minimum mvdd
  MVMAX=1350 #max mvdd
  #MCDEF=820  #default vddci
  #MVDEF=1300 #default mvdd
  # Soc Frequency
  SOCMIN=535
  SOCMAX=1267
  # Soc VDD
  SOCVDDMIN=650
  SOCVDDMAX=1200

  # Manage states
  if [[ -z "$COREINDEX" ]] || [[ "$COREINDEX" = "skip" ]] || [[ "$COREINDEX" = "5" ]]; then
    COREINDEX="2"
  fi

  # Leftover code for older versions
  if [ "$version" = "1.4" ] || [ "$version" = "1.4.5" ] || [ "$version" = "1.4.6" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.4.8" ] || [ "$version" = "1.5.3" ] || [ "$version" = "1.4.9" ] || [ "$version" = "1.5.2" ]; then
    if [ "$COREINDEX" = "1" ]; then
      COREINDEX="2"
    fi
  fi

  # Defaults until Alpha/Beta to avoid bugs
  if [[ -z "$CORECLOCK" ]] || [[ "$CORECLOCK" = "" ]] || [[ "$CORECLOCK" = "skip" ]]; then
    CORECLOCK="1470"
  fi

  if [[ -z "$MVDD" ]] || [[ "$MVDD" = "" ]] || [[ "$MVDD" = "skip" ]]; then
    MVDD="1350"
  fi

  if [[ -z "$VDDCI" ]] || [[ "$VDDCI" = "" ]] || [[ "$VDDCI" = "skip" ]]; then
    VDDCI="850"
  fi

  if [[ -z "$VDDC" ]] || [[ "$VDDC" = "" ]] || [[ "$VDDC" = "skip" ]]; then
    VDDC="785"
  fi

  #######################
  # FANS
  MAXFAN="255"
  RPMMIN=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_min)
  RPMMAX=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_max)
  RPMVAL="0"

  if [ "$FANSPEED" != 0 ]; then
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)
    FANVALUE=$(awk -v n="$FANVALUE" 'BEGIN{print int((n+5)/10) * 10}')

    RPMVAL=$(echo - | awk "{print $RPMMAX / 100 * $FANSPEED}" | cut -f1 -d".")
    RPMVAL=$(printf "%.0f\n" $RPMVAL)
    RPMVAL=$(awk -v n="$RPMVAL" 'BEGIN{print int((n+5)/10) * 10}')

    echo "GPU$GPUID : FANSPEED => $FANSPEED% ($FANVALUE) [RPM: $RPMVAL]"
  else
    FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}" | cut -f1 -d".")
    FANVALUE=$(printf "%.0f\n" $FANVALUE)

    RPMVAL=$(echo - | awk "{print $RPMMAX / 100 * 70}" | cut -f1 -d".")
    RPMVAL=$(printf "%.0f\n" $RPMVAL)
    RPMVAL=$(awk -v n="$RPMVAL" 'BEGIN{print int((n+5)/10) * 10}')

    echo "GPU$GPUID : FANSPEED => 70% ($FANVALUE) [RPM: $RPMVAL]"
  fi

  if [[ $FANVALUE -gt $MAXFAN ]]; then
    FANVALUE=$MAXFAN
  fi

  echo "--**--**-- GPU $1 : NAVI --**--**--"

  # Memory Voltage controller
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
      pvddci="smc_pptable/MemVddciVoltage/1=$AVDDCI smc_pptable/MemVddciVoltage/2=$AVDDCI smc_pptable/MemVddciVoltage/3=$AVDDCI"
    fi
  fi

  # Memory Voltage
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
      pmvdd="smc_pptable/MemMvddVoltage/1=$AMVDD smc_pptable/MemMvddVoltage/2=$AMVDD smc_pptable/MemMvddVoltage/3=$AMVDD"
    fi
  fi

  # SoC Clock Frequency
  if [[ ! -z $SOC && $SOC != "0" && $SOC != "skip" ]]; then
    PARSED_SOC=$SOC
    if [[ $SOC -gt $SOCMAX ]]; then
      PARSED_SOC=950
      echo "SoC can't be higher than $SOCMAX using safe value 950"
    fi
    if [[ $SOC -lt $SOCMIN ]]; then
      PARSED_SOC=$SOCMIN
      # Ignore if set below limit
      echo "SOCCLK value ignored as below $SOCMIN Mhz limit"
    else
      # Calculate Soc Curve
      soc_s0=$PARSED_SOC
      for soc_sl in 532 604 644 738 802; do
        if [[ $soc_sl -lt $SOC ]]; then
          soc_s0=$soc_sl
        else
          break
        fi
      done
      soc_p0="smc_pptable/FreqTableSocclk/0=$soc_s0"
      psoc="$soc_p0 smc_pptable/FreqTableSocclk/1=$PARSED_SOC"
    fi
  fi

  # SoC Voltage
  if [[ ! -z $SOCVDD && $SOCVDD != "0" && $SOCVDD != "skip" ]]; then
    PARSED_SOCVDD=$SOCVDD
    if [[ $SOCVDD -gt $SOCVDDMAX ]]; then
      PARSED_SOCVDD=1050
      echo "SoC can't be higher than $SOCVDDMAX using safe value 950"
    fi
    if [[ $SOCVDD -lt $SOCVDDMIN ]]; then
      PARSED_SOCVDD=$SOCVDDMIN
      # Ignore if set below limit
      echo "SOCCLK value ignored as below $SOCVDDMIN mV limit"
    else
      PARSED_SOCVDD_MAX=$((PARSED_SOCVDD * 4))
      psocvolt="smc_pptable/MaxVoltageSoc=$PARSED_SOCVDD_MAX"
    fi
  fi

  if [[ "$version" != "1.5.4" ]]; then
    # Target temp
    FILE=/media/storage/fans.txt
    TT=69
    if [ -f "$FILE" ]; then
      TARGET=$(cat /media/storage/fans.txt | grep "TARGET_TEMP=" | xargs | sed 's/[^0-9]*//g')
      if [[ ! -z "$TARGET" ]]; then
        TT=$TARGET
        echo "NAVI Fan Curve Target: $TT"
      else
        TT=69
      fi
    else
      TT=69
    fi

    # Reinstall upp if error
    sudo rm /dev/shm/safetycheck.txt &>/dev/null
    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get smc_pptable/MinVoltageGfx &>/dev/shm/safetycheck.txt
    SAFETY=$(cat /dev/shm/safetycheck.txt)
    if [[ $SAFETY == *"has no attribute"* ]] || [[ $SAFETY == *"ModuleNotFoundError"* ]] || [[ $SAFETY == *"table version"* ]]; then
      sudo su minerstat -c "yes | sudo pip3 uninstall setuptools"
      sudo su minerstat -c "yes | sudo pip3 uninstall click"
      sudo su minerstat -c "yes | sudo pip3 uninstall upp"
      sudo su minerstat -c "yes | sudo pip3 uninstall sympy"
      sudo su -c "yes | sudo pip3 uninstall upp"
      sudo su minerstat -c "pip3 install setuptools"
      sudo su minerstat -c "pip3 install sympy"
      sudo su minerstat -c "pip3 install git+https://labs.minerstat.farm/repo/upp"
      sudo su -c "pip3 install git+https://labs.minerstat.farm/repo/upp"
    fi

    # Radeon Pro Patch
    proArgs=""
    isRadeonPro=$(sudo timeout 20 /home/minerstat/minerstat-os/bin/amdcovc | grep "PCI ${11}:" | grep -E "Pro|PRO" | wc -l)

    if [[ "$isRadeonPro" -gt "0" ]]; then
      for ((i = 0; i <= 13; i += 1)); do
        proArgs+="overdrive_table/cap/$i=1 "
      done
    fi

    # Thermal Design Current
    TdcLimit=""
    TDC=$(sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table get smc_pptable/TdcLimit/1 2>/dev/null | xargs | grep -c "30")
    if [[ "$TDC" = "1" ]]; then
      TdcLimit="smc_pptable/TdcLimit/1=33"
    fi
    # Manual input
    if [[ ! -z $TDCMAX && $TDCMAX != "0" && $TDCMAX != "skip" ]]; then
      if [[ $TDCMAX -lt 25 ]]; then
        echo "Error: TdcLimit can't be lower than 25"
      else
        if [[ $TDCMAX -lt 50 ]]; then
          TdcLimit="smc_pptable/TdcLimit/1=$TDCMAX"
        else
          echo "Error: TdcLimit can't be more than 50"
        fi
      fi

    fi

    # Apply VDDGFX
    # Only above 1.8.0 msOS package versions
    SYMP=$(ls /home/minerstat/.local/lib/python*/site-packages/ | grep -c "sympy")
    OREV="smc_pptable/VcBtcEnabled=1 overdrive_table/min/7=$VDDC overdrive_table/min/5=500 smc_pptable/FanTargetTemperature=90 smc_pptable/FanTargetGfxclk=500"
    if [[ "$version_r" -gt "176" ]] || [[ "$SYMP" -gt "0" ]]; then
      sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table vddgfx $CORECLOCK $VDDC --write
    else
      # Only apply this for < v1.8.0 OS versions
      OREV="smc_pptable/VcBtcEnabled=0 overdrive_table/min/7=600 overdrive_table/min/5=600 smc_pptable/FanTargetTemperature=$TT smc_pptable/FanTargetGfxclk=1000 smc_pptable/DpmDescriptor/0/VoltageMode=2 smc_pptable/MinVoltageGfx=2400 smc_pptable/MinVoltageUlvGfx=2500 smc_pptable/FreqTableGfx/1=$CORECLOCK"
    fi

    # Apply new table
    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set smc_pptable/FreqTableGfx/0=1150
    sudo /home/minerstat/.local/bin/upp -p /sys/class/drm/card$GPUID/device/pp_table set \
      overdrive_table/max/8=1200 overdrive_table/max/6=1200 overdrive_table/max/7=1200 overdrive_table/min/3=0 $OREV $TdcLimit \
      smc_pptable/MinVoltageUlvSoc=825 smc_pptable/FreqTableFclk/0=1550 $pmvdd $pvddci $psoc $psocvolt \
      smc_pptable/FanStopTemp=0 smc_pptable/FanStartTemp=10 smc_pptable/FanZeroRpmEnable=0 smc_pptable/FanTargetTemperature=90 smc_pptable/FanTargetGfxclk=500 smc_pptable/dBtcGbGfxDfllModelSelect=2 smc_pptable/FreqTableUclk/3=$MEMCLOCK $proArgs --write
  fi

  # Apply powerlimit
  if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "skip" ]] && [[ "$POWERLIMIT" != "pwrskip" ]] && [[ "$POWERLIMIT" != "pwrSkip" ]] && [[ $POWERLIMIT == *"pwr"* ]]; then
    POWERLIMIT=$(echo $POWERLIMIT | sed 's/[^0-9]*//g')
    if [[ ! -z "$POWERLIMIT" ]] && [[ "$POWERLIMIT" != "0" ]]; then
      # Navi limits (default 180)
      PW_MIN=$((80 * 1000000))
      PW_MAX=$((250 * 1000000))
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

  TESTD=$(timeout 5 dpkg -l | grep opencl-amdgpu-pro-icd | head -n1 | awk '{print $3}' | xargs | cut -f1 -d"-")

  if [ -z "$TESTD" ]; then
    TESTD=$(timeout 5 dpkg -l | grep amdgpu-pro-rocr-opencl | head -n1 | awk '{print $3}' | xargs | cut -f1 -d"-")
  fi

  # Disable fans this will ramp up RPM to max
  echo "Waiting for fans 2 second as new pptable just got applied"
  sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
  sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_enable" 2>/dev/null
  sleep 1

  if [ "$TESTD" = "20.30" ] || [ "$TESTD" = "20.40" ] || [ "$TESTD" = "20.45" ] || [ "$TESTD" = "20.50" ] || [ "$TESTD" = "21.10" ] || [ "$TESTD" = "21.20" ] || [ "$TESTD" = "21.30" ] || [ "$TESTD" = "21.50" ]; then

    # Enable fan and manual control
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_enable" 2>/dev/null

    # Set new target
    sudo su -c "echo 255 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%
    sudo timeout 5 /home/minerstat/minerstat-os/bin/rocm-smi --setfan $FANVALUE -d $GPUID
    sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1" 2>/dev/null # 70%

    sleep 1

    #if [[ "$version" = "1.7.3" ]] || [[ "$version" = "1.7.2" ]] || [[ "$version" = "1.7.1" ]] || [[ "$version" = "1.7.0" ]]; then
    RB=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1 | xargs)
    echo "Reading back fan value .. $RB"
    if [[ "$RB" = "0" ]]; then
      # RPM KICK
      echo "RPM KICK Method $RB"
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_enable" 2>/dev/null
      sudo su -c "echo $RPMVAL > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/fan1_target" 2>/dev/null
      sleep 2
    fi

    sleep 2

    RB=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1 | xargs)
    echo "Reading back fan value .. $RB"
    if [[ "$RB" = "0" ]]; then
      echo "2" >/dev/shm/fantype.txt
      echo "Driver autofan kick .."
      sleep 1
      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
      sleep 1
      sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
      sleep 1
      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
      sleep 1
    else
      sudo rm /dev/shm/fantype.txt 2>/dev/null
    fi

    RB=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1 | xargs)
    if [[ "$RB" = "0" ]]; then
      # 100% fans
      echo "2" >/dev/shm/fantype.txt
      echo "Nothing worked 100% fans then auto"
      sudo su -c "echo 0 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
      sleep 1
      sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/hwmon/hwmon*/pwm1_enable" 2>/dev/null
    fi

  else
    echo "2" >/dev/shm/fantype.txt
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

  # MemoryClock
  if [ "$MEMCLOCK" != "skip" ]; then
    # Auto fix Windows Clocks to linux ones
    # Windows is memclock * 2
    if [[ $MEMCLOCK -gt "2300" ]]; then
      echo "!! MEMORY CLOCK CONVERTED TO LINUX FORMAT [WINDOWS_MEMCLOCK/2]"
      MEMCLOCK=$((MEMCLOCK / 2))
    fi
    if [[ $MEMCLOCK -gt "2300" ]]; then
      echo "!! Invalid memory clock detected, auto fixing.."
      echo "Maximum recommended clock atm 950Mhz (Windows: 950*2 = 1900Mhz)"
      echo "You have set $MEMCLOCK Mhz reducing back to 950Mhz"
      MEMCLOCK=1025
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

  if [[ "$CORECLOCK" != "skip" ]]; then
    echo "GPU$GPUID : CORECLOCK => $CORECLOCK Mhz ($VDDC mV, state: $COREINDEX)"

    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "s 1 $CORECLOCK"
    sudo /home/minerstat/minerstat-os/bin/msos_od_clk $GPUID "vc 2 $CORECLOCK"

    sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
  fi

  ###########################################################################
  if [ "$version" = "1.4" ] || [ "$version" = "1.4.5" ] || [ "$version" = "1.4.6" ] || [ "$version" = "1.4.7" ] || [ "$version" = "1.4.8" ]; then
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "echo '3' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
  fi

  # Apply Changes
  sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
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

  TEST=$(screen -list | grep -wc soctimer)
  if [ "$TEST" = "0" ]; then
    screen -A -m -D -S soctimer sudo bash /home/minerstat/minerstat-os/bin/soctimer $GPUID &
    echo "#!/bin/bash" >/home/minerstat/clock_cache
    echo "sudo bash /home/minerstat/minerstat-os/bin/overclock_sienna.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}" >>/home/minerstat/clock_cache
  else
    echo "sudo bash /home/minerstat/minerstat-os/bin/overclock_sienna.sh $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13}" >>/home/minerstat/clock_cache
  fi

  exit 1

fi
