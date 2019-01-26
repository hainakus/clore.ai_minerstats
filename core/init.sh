#!/bin/bash

while true
do

    echo "-*- BACKGROUND SERVICE -*-"

    #HOSTNAME
    TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g')"
    WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g')"

    #FREE SPACE in Megabyte - SDA1
    STR1="$(df -hm | grep sda1 | awk '{print $4}')"

    #CPU USAGE
    STR2="$(mpstat | awk '$13 ~ /[0-9.]+/ { print 100 - $13 }')"

    #REMOTE IP ADDRESS
    STR4="$(wget -qO- http://ipecho.net/plain ; echo)"

    #LOCAL IP ADDRESS
    STR3="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v $STR4)"

    #FREE MEMORY
    STR5="$(free -m | grep 'Mem' | awk '{print $4}')"

    # TELEPROXY ID
    TELEID=$(cat /home/minerstat/minerstat-os/bin/screenlog.0 | grep WebUI | rev | cut -d ' ' -f 1 | rev | xargs)

    echo ""
    echo "-*- $TOKEN $WORKER -*-"
    echo "Free Space: $STR1"
    echo "CPU Usage: $STR2"
    echo "Free Memory: $STR5"
    echo "Local IP: $STR3"
    echo "Remote IP: $STR4"
    echo ""

    #SEND INFO
    wget -qO- "https://api.minerstat.com/v2/set_os_status.php?token=$TOKEN&worker=$WORKER&space=$STR1&cpu=$STR2&localip=$STR3&remoteip=$STR4&freemem=$STR5&teleid=$TELEID" ; echo

    echo "-*- MINERSTAT LISTENER -*-"
    RESPONSE="$(wget -qO- "https://api.minerstat.com/v2/os_listener.php?token=$TOKEN&worker=$WORKER" ; echo)"

    echo "RESPONSE: $RESPONSE"

    if [ $RESPONSE = "REBOOT" ]; then
        #sudo reboot -f
        sudo su -c "echo 1 > /proc/sys/kernel/sysrq";
        sudo su -c "echo b > /proc/sysrq-trigger"
    fi

    if [ $RESPONSE = "SHUTDOWN" ]; then
        #sudo shutdown -h now
        sudo su -c "echo 1 > /proc/sys/kernel/sysrq";
        sudo su -c "echo o > /proc/sysrq-trigger";
    fi

    if [ $RESPONSE = "null" ]; then
        echo "No remote command pending..";
    fi

    sleep 40
done
