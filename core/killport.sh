#!/bin/sh

PORT=42000

if [ ! -z "$1" ]; then
  PORT=$1
fi

for con in `sudo netstat -anp | grep $PORT | grep TIME_WAIT | awk '{print $5}'`; do
 sudo /home/minerstat/minerstat-os/core/killcx.pl $con lo
done
