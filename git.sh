#! /usr/bin/bash

cd /home/minerstat/minerstat-os/
chmod -R 777 *

exec 2> /home/minerstat/debug.txt
git remote set-url origin http://labs.minerstat.farm/repo/minerstat-os.git
git config --global user.email "dump@minerstat.com"
git config --global user.name "minerstat"
NETBOT="$(git pull --no-edit)"

echo $NETBOT

sleep 1

if grep -q "merge" /home/minerstat/debug.txt;
then

  sleep 2

  sudo git commit -a -m "Init"
  sudo git merge --strategy-option theirs --no-edit
  sudo git add * -f
  sudo git commit -a -m "Fix done"

  cd /home/minerstat/minerstat-os/
  chmod -R 777 *

fi

if grep -q "merge" /home/minerstat/debug.txt;
then
  # Check lost
  STARTJS=$(wc -c < /home/minerstat/minerstat-os/start.js)
  WORKSH=$(wc -c < /home/minerstat/minerstat-os/bin/work.sh)
  JOBSSH=$(wc -c < /home/minerstat/minerstat-os/bin/jobs.sh)
  if [ "$STARTJS" = "0" ] || [ "$WORKSH" = "0" ] || [ "$JOBSSH" = "0" ]; then
    sudo su -c "sudo screen -X -S minew quit"
    sudo su -c "sudo screen -X -S fakescreen quit"
    sudo su -c "screen -ls minew | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
    sudo su minerstat -c "screen -X -S fakescreen quit"
    screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done
    sudo su minerstat -c "screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
    sudo killall node
    sleep 0.25
    cd /home/minerstat
    sudo rm /home/minerstat/recovery.sh
    wget -o /dev/null https://labs.minerstat.farm/repo/minerstat-os/-/raw/master/core/recovery.sh
    sudo chmod 777 /home/minerstat/recovery.sh
    sudo bash /home/minerstat/recovery.sh
    sudo sh /home/minerstat/minerstat-os/bin/overclock.sh &
    sleep 15
    sudo su minerstat -c "screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh"
    sleep 2
    sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"
  fi
fi

sudo rm /home/minerstat/debug.txt

# APPLY NEW BASHRC
sudo cp -fR /home/minerstat/minerstat-os/core/.bashrc /home/minerstat

chmod -R 777 *

# NPM UPDATE
# npm update

sudo /home/minerstat/minerstat-os/bin/jobs.sh
sudo sync &
