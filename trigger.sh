#!/bin/bash 
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
    bash oc.sh 0 1 2 3 4 5
echo "FINISHED OC SETS"
sleep 5
echo "START MINING"
    bash btg.sh 
fi 

else
    pkill -f $SERVICE
sleep 5
    bash oc_reset_fan.sh 0 1 2 3 4 5
echo "FINISHED OC RESETS"
fi
