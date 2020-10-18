#!/bin/bash
exec 2>/dev/null

if ! screen -list | grep -q "dummy"; then
  screen -A -m -d -S dummy sleep 22176000

  # Stop before OC
  echo "stopboot" > /tmp/stop.pid;
  echo "stop" > /tmp/justbooted.pid;
  screen -A -m -d -S just sudo bash /home/minerstat/minerstat-os/core/justboot

  screen -S listener -X quit > /dev/null # kill running process
  screen -A -m -d -S listener sudo bash /home/minerstat/minerstat-os/core/init.sh

  TESTLOGIN=$(timeout 2 systemctl list-jobs)
  if [ "$TESTLOGIN" != "No jobs running." ]; then
    sudo systemctl restart systemd-logind.service &
  fi

  # validate OC
  screen -A -m -d -S checkclock sudo bash /home/minerstat/minerstat-os/core/checkclock

  # FIX CTRL + ALT + F1
  sudo systemctl start nvidia-persistenced > /dev/null &
  screen -A -m -d -S chvt sudo /home/minerstat/minerstat-os/bin/chvta

  NVIDIA="$(nvidia-smi -L)"
  AMDDEVICE=$(lsmod | grep amdgpu | wc -l)
  #if [ "$AMDDEVICE" = "0" ]; then
  #  AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
  #fi
  NVIDIADEVICE=$(lsmod | grep nvidia | wc -l)
  #if [ "$NVIDIADEVICE" = "0" ]; then
  #  NVIDIADEVICE=$(sudo lshw -C display | grep "driver=nvidia" | wc -l)
  #fi
  #if [ "$NVIDIADEVICE" = "0" ]; then
  #  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)
  #fi

  #echo ""
  #echo "\033[1;34m================= GPUs =================\033[0m"
  #echo "\033[1;34m== \033[1;32mAMD:\033[0m $AMDDEVICE"
  #echo "\033[1;34m== \033[1;32mNVIDIA:\033[0m $NVIDIADEVICE"
  #echo ""

  echo -e "\033[1;34m==\033[0m Configuring network adapters ...\033[0m"
  SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g' | xargs | wc -L)
  DHCP=$(cat /media/storage/network.txt | grep "DHCP=" | sed 's/DHCP=//g' | sed 's/"//g')

  #sudo screen -A -m -d -S restartnet sudo /etc/init.d/networking restart

  echo -e "\033[1;34m==\033[0m Waiting for connection ...\033[0m"

  sleep 1
  HAVECONNECTION="true"
  ping -c1 1.1.1.1 -w 1 &>/dev/null && HAVECONNECTION="true" || HAVECONNECTION="false"
  if [ "$HAVECONNECTION" = "false" ]; then
    if [ "$SSID" -gt 0 ]; then
      cd /home/minerstat/minerstat-os/core
      sudo bash wifi.sh

    else

      if [ "$DHCP" != "NO" ]; then
        cd /home/minerstat/minerstat-os/bin
        sudo bash /home/minerstat/minerstat-os/core/dhcp
        #sudo dhclient -v -r
      else
        cd /home/minerstat/minerstat-os/bin
        sudo bash static.sh
      fi
    fi
  fi

  # Cache management
  ping -c1 104.24.98.231 -w 1 &>/dev/null && HAVECONNECTION="true" || HAVECONNECTION="false"
  if [ "$HAVECONNECTION" = "false" ]; then
    sudo timeout 10 service network-manager restart
    sudo timeout 10 /usr/sbin/netplan apply
    sudo timeout 10 /home/minerstat/minerstat-os/core/dnser
    sleep 2
  fi

  ping -c1 api.minerstat.com -w 1 &>/dev/null && HAVECONNECTION="true" || HAVECONNECTION="false"
  if [ "$HAVECONNECTION" = "false" ]; then
    sudo timeout 10 /home/minerstat/minerstat-os/core/dnser
    sleep 2
  fi

  echo -e "\033[1;34m==\033[0m Updating the system ...\033[0m"

  #sudo update-pciids
  cd /home/minerstat/minerstat-os
  sudo bash git.sh

  sudo chmod -R 777 /home/minerstat/minerstat-os/*

  #echo "Moving MSOS config.js to / (LINUX)"
  sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"

  sleep 1
  sudo service dgm stop > /dev/null &
  sudo chvt 1

  echo -e "\033[1;34m==\033[0m Overclocking ...\033[0m"
  cd /home/minerstat/minerstat-os/
  sudo node stop > /dev/null
  sudo su minerstat -c "screen -X -S minerstat-console quit" > /dev/null
  echo "stop" > /tmp/stop.pid
  sudo su -c "sudo screen -X -S minew quit" > /dev/null
  cd /home/minerstat/minerstat-os/bin

  TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
  WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"

  # Remove pending commands
  wget -qO- --timeout=10 "https://api.minerstat.com/v2/set_node_config.php?token=$TOKEN&worker=$WORKER" &>/dev/null &

  # PCI_BUS_ID
  if [ "$AMDDEVICE" -gt 0 ]; then

    HWMEMORY=$(cd /home/minerstat/minerstat-os/bin/; cat amdmeminfo.txt)
    if [ -z "$HWMEMORY" ] || [ -f "/dev/shm/amdmeminfo.txt" ]; then
      HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
    fi
    sudo chmod 777 /dev/shm/amdmeminfo.txt
    if [ ! -f "/dev/shm/amdmeminfo.txt" ]; then
      timeout 30 sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -q > /dev/shm/amdmeminfo.txt &
      sudo cp -rf /dev/shm/amdmeminfo.txt /home/minerstat/minerstat-os/bin
      sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
      # fix issue with meminfo file
      RBC=$(cat /dev/shm/amdmeminfo.txt)
      if [[ $RBC == *"libamdocl"* ]]; then
        sed -i '/libamdocl/d' /dev/shm/amdmeminfo.txt
      fi
      HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
    fi
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwMemory=$HWMEMORY" "https://api.minerstat.com/v2/set_node_config_os.php"
  fi

  # MCLOCK
  echo -e "\033[1;34m==\033[0m Adjusting clocks in the background ...\033[0m"
  #sudo chvt 1
  sudo bash /home/minerstat/minerstat-os/bin/overclock.sh

  if [ "$AMDDEVICE" -gt 0 ]; then
    echo -e "\033[1;34m==\033[0m Applying AMD Memory Tweak ...\033[0m"
    sudo screen -A -m -d -S delaymem bash /home/minerstat/minerstat-os/bin/setmem.sh
  fi

  echo -e "\033[1;34m==\033[0m Initializing minerstat OS ...\033[0m"
  cd /home/minerstat/minerstat-os
  sudo su -c "sudo screen -X -S minew quit" > /dev/null
  sudo su -c "sudo screen -X -S fakescreen quit" > /dev/null
  sudo su -c "screen -ls minew | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done" > /dev/null
  sudo su minerstat -c "screen -X -S fakescreen quit" > /dev/null
  screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done
  sudo su minerstat -c "screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
  sudo su minerstat -c "screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh"
  sudo rm /tmp/stop.pid > /dev/null
  sleep 2
  sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"

  echo -e "\033[1;34m==\033[0m Minerstat started in the background ...\033[0m"

  if grep -q experimental "/etc/lsb-release"; then
    if [ "$AMDDEVICE" -gt 0 ]; then
      echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
      echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
      sudo apt-get --yes --force-yes install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
    fi
  fi

  echo -e "\033[1;34m==\033[0m Starting local web console ...\033[0m"
  cd /home/minerstat/minerstat-os/bin
  #./shellinaboxd --port 4200 -b --css "/home/minerstat/minerstat-os/core/white-on-black.css" --disable-ssl

  if [ ! -z "$NVIDIA" ]; then

    if echo "$NVIDIA" | grep -iq "^GPU 0:"; then

      ETHPILLARGS=$(cat /media/storage/settings.txt 2>/dev/null | grep 'OHGODARGS="' | sed 's/OHGODARGS="//g' | sed 's/"//g')
      ETHPILLDELAY=$(cat /media/storage/settings.txt 2>/dev/null | grep 'OHGODADELAY=' | sed 's/[^0-9]*//g')
      NVIDIA_LED=$(cat /media/storage/settings.txt | grep "NVIDIA_LED=" | sed 's/[^=]*\(=.*\)/\1/' | tr --delete = | xargs)

      if [ "$NVIDIA_LED" = "OFF" ]; then
        sudo nvidia-settings --assign GPULogoBrightness=0 -c :0
      fi

      if grep -q experimental "/etc/lsb-release"; then
        CHECKAPTXN=$(dpkg -l | grep "libegl1-amdgpu-pro" | wc -l)
        if [ "$CHECKAPTXN" -gt "0" ]; then
          sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
        fi
      fi

      if [ "$ETHPILLDELAY" != "999" ]; then
        cd /home/minerstat/minerstat-os/bin
        sudo chmod 777 /home/minerstat/minerstat-os/bin/OhGodAnETHlargementPill-r2
        screen -A -m -d -S ethboost sudo bash ethpill.sh $ETHPILLARGS $ETHPILLDELAY
      fi

    fi
  fi

  echo -e "\033[1;34m==\033[0m Initializing jobs ...\033[0m"
  # Safety check for sockets, if double instance kill
  SNUM=$(sudo su minerstat -c "screen -list | grep -c sockets")
  if [ "$SNUM" != "1" ]; then
    sudo su minerstat -c "screen -ls | grep sockets | cut -d. -f1 | awk '{print $1}' | xargs kill -9; screen -wipe; sudo killall sockets; sleep 0.5; sudo killall sockets; screen -A -m -d -S sockets sudo bash /home/minerstat/minerstat-os/core/sockets" > /dev/null
  fi
  cd /home/minerstat/minerstat-os/bin
  sudo bash jobs.sh $AMDDEVICE &

  sleep 1
  sudo chvt 1

  cd /home/minerstat/minerstat-os/core
  sudo bash expand.sh &

  echo -e "\033[1;34m==\033[0m Waiting for console output ...\033[0m"

  sudo chvt 1
  sudo su minerstat -c "sh /home/minerstat/minerstat-os/core/view"
  sleep 1
  exec bash
  source ~/.bashrc

fi
