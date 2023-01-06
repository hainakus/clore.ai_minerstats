#!/usr/bin/bash
start=$1
end=$2

start=$(date -d $start +%Y%m%d)
end=$(date -d $end +%Y%m%d)

while [[ $start -le $end ]]
do
	echo $start
    bash trigger.sh

    sleep 60
	start=$(date -d"$start + 1 minute" +"%Y%m%d")
echo $start
done


