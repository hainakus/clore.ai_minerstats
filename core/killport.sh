#!/bin/sh

sudo su -c "echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout"

PORT=42000

if [ ! -z "$1" ]; then
  PORT=$1
fi

sudo kill -9 $(pidof PhoenixMiner) 2> /dev/null

interface=$(ip addr | awk '/state UP/ {print $2}' | sed 's/.$//')
#sudo su -c "kill $(sudo lsof -t -i:$PORT)"
#sudo fuser -k $PORT/tcp

now=$(date +"%T")
printf "\033[1;34m== \033[0m$now:\033[1;32m Freeing up API Port at: $PORT [$interface]\033[0m ..."

for con in `sudo netstat -anp | grep $PORT | grep TIME_WAIT | awk '{print $5}'`; do
  sudo /home/minerstat/minerstat-os/core/killcx.pl $con lo >/dev/null
  #sudo /home/minerstat/minerstat-os/core/killcx.pl $con $interface
done

if [ "$PORT" != "4028" ] && [ "$PORT" != "7887"]; then

  RETEST=$(sudo netstat -anp | grep $PORT 2> /dev/null | grep TIME_WAIT 2> /dev/null | awk '{print $5}' | wc -l)

  until [ $RETEST -eq 0 ]
  do
    #sudo su -c "kill $(sudo lsof -t -i:$PORT)"
    #sudo fuser -k $PORT/tcp
    sleep 9
    RETEST=$(sudo netstat -p 2> /dev/null | grep -c $PORT 2> /dev/null)
  done 

fi

printf "\033[1;32m done\033[0m"

sudo su -c "echo 10 > /proc/sys/net/ipv4/tcp_fin_timeout"
