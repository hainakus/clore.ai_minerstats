#!/bin/bash
exec 2>/dev/null

if [ ! $1 ]; then
    echo ""
    echo "--- EXAMPLE ---"
    echo "./overclock_vega.sh 1 2 3 4 5 6"
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

    echo "--**--**-- GPU $1 : VEGA 56/64 --**--**--"
  
    # Requirements
    sudo su -c "echo 1 > /sys/class/drm/card0/device/hwmon/hwmon0/pwm1_enable"
    sudo su -c "echo manual > /sys/class/drm/card0/device/power_dpm_force_performance_level"
    sudo su -c "echo 4 > /sys/class/drm/card0/device/pp_power_profile_mode" # Compute Mode

    # Core clock & VDDC
    sudo su -c "echo 's 7 $3 $5' > /sys/class/drm/card$1/device/pp_od_clk_voltage"
    sudo su -c "echo 0 > /sys/class/drm/card0/device/pp_sclk_od"
    sudo su -c "echo 1 > /sys/class/drm/card0/device/pp_sclk_od"

    # Memory Clock
    sudo su -c "echo 'm 3 $2 1100' > /sys/class/drm/card$1/device/pp_od_clk_voltage"
    sudo su -c "echo 0 > /sys/class/drm/card0/device/pp_mclk_od"
    sudo su -c "echo 1 > /sys/class/drm/card0/device/pp_mclk_od"

    # FANS
    if [ "$FANSPEED" != 0 ]
    then
        sudo ./amdcovc fanspeed:$GPUID=$FANSPEED | grep "Setting"
    else
        sudo ./amdcovc fanspeed:$GPUID=70 | grep "Setting"
    fi

    # Check current states
    sudo su -c "cat /sys/class/drm/card0/device/pp_od_clk_voltage"
    #sudo cat /sys/kernel/debug/dri/0/amdgpu_pm_info

    exit 1

fi
