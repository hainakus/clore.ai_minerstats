#! /usr/bin/bash

cd /home/minerstat/minerstat-os/
chmod -R 777 *

exec 2> /home/minerstat/debug.txt
git config --global user.email "dump@minerstat.com"
git config --global user.name "minerstat"
NETBOT="$(git pull --no-edit)"

echo $NETBOT

sleep 1

if grep -q "merge" /home/minerstat/debug.txt;
then

sleep 2

sudo git commit -a -m "Init"
sudo git merge --no-edit
sudo git add * -f
sudo git commit -a -m "Fix done"

cd /home/minerstat/minerstat-os/
chmod -R 777 *

fi

sudo rm /home/minerstat/debug.txt

# APPLY NEW BASHRC
sudo cp -fR /home/minerstat/minerstat-os/core/.bashrc /home/minerstat

chmod -R 777 *

# NPM UPDATE
# npm update

sudo /home/minerstat/minerstat-os/bin/jobs.sh
