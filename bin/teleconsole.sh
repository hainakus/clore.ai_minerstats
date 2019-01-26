#!/bin/sh
#exec 2>/dev/null

sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0

RESTARTEVERY=3600
CURRENTSYNC=0

echo "*-*-* Teleconsole *-*-*"

run() {
    screen -L -A -m -d -S teleproxy ./teleproxy -f minerstat.com:3022
}


start()
{
    echo "-- Starting Teleconsole --"
    cd /home/minerstat/minerstat-os/bin/
    sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0
    run
}

forcekill() {
    sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0
    sudo killall teleproxy
    sleep 0.5
    sudo killall teleproxy
    sleep 0.8
    sudo killall teleproxy
    sleep 5
    start
}

check()
{
    echo "-- Checking health on Teleconsole --"
    CURRENTSYNC=$(($CURRENTSYNC + 60))
    if [ "$CURRENTSYNC" -gt "$RESTARTEVERY" ]; then
        echo "Timeout, Restarting Teleconsole";
        CURRENTSYNC=0
        forcekill
        sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0
        #start
    fi
    # Basic health check
    SEARCH=$(cat screenlog.0 | grep "SSH tunnel cannot be established" | wc -L)
    if [ "$SEARCH" -gt 0 ]; then
        echo "Seems teleconsole crashed"
        forcekill
        sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0
        #start
    fi
    # Over
    CRASH=$(cat screenlog.0 | grep "You have ended your session" | wc -L)
    if [ "$CRASH" -gt 0 ]; then
        echo "Seems teleconsole crashed"
        forcekill
        sudo echo -n "" > /home/minerstat/minerstat-os/bin/screenlog.0
        #start
    fi
    # File size empty
    CHARS=$(cat screenlog.0 | wc -L)
    if [ "$CHARS" -lt 70 ]; then
        forcekill
    fi

}

# Start with APP
forcekill


# Start loop
while true
do
    sleep 30
    TELEID=$(cat /home/minerstat/minerstat-os/bin/screenlog.0 | grep WebUI | rev | cut -d ' ' -f 1 | rev | xargs)
    echo "TeleID: "$TELEID
    check
done
