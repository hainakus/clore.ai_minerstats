#!/bin/bash
start=$1
end=$2

start=$(date -d $start +%Y%m%d)
end=$(date -d $end +%Y%m%d)

while [[ $start -le $end ]]
do
	echo $start
    RESULT=$(curl -s 'https://solo-btg.2miners.com/api/stats' | json -Ha luck)
    SERVICE=miniZ
    echo "$RESULT"
    v=${RESULT%.*}
    if [  "$v" -gt 82 ]; then
      if pgrep -x "$SERVICE" >/dev/null
    then
        echo "$SERVICE is running"
    else
        echo "$SERVICE stopped"
        #bash oc.sh 0 1 2 3 4 5
    echo "FINISHED OC SETS"
    sleep 5
    echo "START MINING"
         ./miniZ --url=GfDbbYcz7to4qqs2fbkswWxZRQtKnDYPdi.BEAST@solo-btg.2miners.com:4141 --power=280 --memclock=1000 --fanspeed=90  --gpuclock=0
    fi

    else
        pkill -f $SERVICE
    sleep 5
       # bash oc_reset_fan.sh 0 1 2 3 4 5
    echo "FINISHED OC RESETS"
    fi

    sleep 60
	start=$(date -d"$start + 1 minute" +"%Y%m%d")
echo $start
done


