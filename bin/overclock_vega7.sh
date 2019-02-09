#!/bin/bash
exec 2>/dev/null

if [ ! $1 ]; then
    echo ""
    echo "--- EXAMPLE ---"
    echo "./overclock_vega7.sh 1 2 3 4 5"
    echo "1 = GPUID"
    echo "2 = Memory Clock"
    echo "3 = Core Clock"
    echo "4 = Fan Speed"
    echo "5 = VDDC"
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
    VDDCI=$6

    echo "--**--**-- GPU $1 : VEGA VII --**--**--"

    MAXFAN=$(cat /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1_max)

    # Requirements
    sudo su -c "echo manual > /sys/class/drm/card$GPUID/device/power_dpm_force_performance_level"
    sudo su -c "echo 4 > /sys/class/drm/card$GPUID/device/pp_power_profile_mode"

    # MemoryClock
    if [ "$MEMCLOCK" != "skip" ]
    then
    sudo su -c "echo 'm 1 $MEMCLOCK' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_mclk_od"
    sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_mclk_od"

    sudo su -c "echo 2 > /sys/class/drm/card$GPUID/device/pp_dpm_mclk"
    fi

    # CoreClock
    if [ "$VDDC" != "0" ]
    then
        echo ""
    else
        VDDC="1114" # DEFAULT FOR 1801Mhz @1114mV
    fi

    if [ "$VDDC" != "skip" ]
    then
      if [ "$CORECLOCK" != "skip" ]
      then
        sudo su -c "echo 's 1 $CORECLOCK' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 'vc 1 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"
        sudo su -c "echo 'vc 2 $CORECLOCK $VDDC' > /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

        sudo su -c "echo '0' > /sys/class/drm/card$GPUID/device/pp_sclk_od"
        sudo su -c "echo '1' > /sys/class/drm/card$GPUID/device/pp_sclk_od"

        sudo su -c "echo 7 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
        sudo su -c "echo 8 > /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
      fi
    fi

    # Apply Changes
    sudo su -c "echo 'c'> /sys/class/drm/card$GPUID/device/pp_od_clk_voltage"

    # ECHO Changes
    sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_sclk"
    sudo su -c "cat /sys/class/drm/card$GPUID/device/pp_dpm_mclk"

    # FANS
    sudo su -c "echo 1 > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1_enable"
    if [ "$FANSPEED" != 0 ]
    then
        FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * $FANSPEED}")
        FANVALUE=$(printf "%.0f\n" $FANVALUE)
        sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1" # user input %
    else
        FANVALUE=$(echo - | awk "{print $MAXFAN / 100 * 70}")
        FANVALUE=$(printf "%.0f\n" $FANVALUE)
        sudo su -c "echo $FANVALUE > /sys/class/drm/card$GPUID/device/hwmon/hwmon0/pwm1" # 70%
    fi


    exit 1

fi
