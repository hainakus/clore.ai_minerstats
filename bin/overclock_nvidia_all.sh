#!/bin/bash
exec 2>/dev/null

if [ ! $1 ]; then
    echo ""
    echo "--- EXAMPLE ---"
    echo "./overclock_nvidia_all.sh 1 2 3 4"
    echo "1 = POWER LIMIT in Watts (Example: 120 = 120W) [ROOT REQUIRED]"
    echo "2 = GLOBAL FAN SPEED (100 = 100%)"
    echo "3 = Memory Offset"
    echo "4 = Core Offset"
    echo ""
    echo "-- Full Example --"
    echo "./overclock_nvidia_all.sh 0 120 80 1300 100"
    echo ""
fi

if [ $1 ]; then
    POWERLIMITINWATT=$1
    FANSPEED=$2
    MEMORYOFFSET=$3
    COREOFFSET=$4

    ## BULIDING QUERIES
    STR1=""
    STR2=""
    STR3=""
    STR4="-c :0"

    # DETECTING VIDEO CARD FOR PERFORMACE LEVEL

    QUERY="$(sudo nvidia-smi -i 0 --query-gpu=name --format=csv,noheader | tail -n1)"

    echo "--- GPU $GPUID: $QUERY ---";

    # DEFAULT IS 3 some card requires only different
    PLEVEL=3

    if echo "$QUERY" | grep "1050" ;then PLEVEL=2
    elif echo "$QUERY" | grep "P106-100" ;then PLEVEL=2
    elif echo "$QUERY" | grep "P102-100" ;then PLEVEL=1
    elif echo "$QUERY" | grep "P104-100" ;then PLEVEL=1
    elif echo "$QUERY" | grep "P106-090" ;then PLEVEL=1
    fi


    echo "--- PERFORMANCE LEVEL: $PLEVEL ---";

    #################################£
    # POWER LIMIT

    if [ "$POWERLIMITINWATT" -ne 0 ]
    then
        if [ "$POWERLIMITINWATT" != "skip" ]
        then
            sudo nvidia-smi -pl $POWERLIMITINWATT
        fi
    fi

    #################################£
    # FAN SPEED

    if [ "$FANSPEED" != "0" ]
    then
        echo "--- MANUAL GPU FAN MOD. ---"
    else
        echo "--- AUTO FAN SPEED (by Drivers) ---"
        STR1="-a GPUFanControlState=0"
    fi

    if [ "$FANSPEED" != "skip" ]
    then
        STR1="-a GPUFanControlState=1 -a GPUTargetFanSpeed="$FANSPEED""
    fi

    #################################£
    # CLOCKS

    if [ "$MEMORYOFFSET" != "skip" ]
    then
        if [ "$MEMORYOFFSET" != "0" ]
        then
            STR2="-a GPUMemoryTransferRateOffset["$PLEVEL"]="$MEMORYOFFSET""
        fi
    fi

    if [ "$COREOFFSET" != "skip" ]
    then
        if [ "$COREOFFSET" != "0" ]
        then
            STR3="-a GPUGraphicsClockOffset["$PLEVEL"]="$COREOFFSET""
        fi
    fi


    #################################£
    # APPLY THIS GPU SETTINGS AT ONCE
    FINISH="$(sudo nvidia-settings $STR1 $STR2 $STR3 $STR4)"
    echo $FINISH

    sleep 2
    sudo chvt 1

fi
