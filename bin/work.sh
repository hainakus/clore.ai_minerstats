if ! screen -list | grep -q "dummy"; then

  # Stop before OC
  echo "stopboot" > /tmp/stop.pid > /dev/null 2>&1;
  echo "stop" > /tmp/justbooted.pid > /dev/null 2>&1;
  screen -A -m -d -S just sudo bash /home/minerstat/minerstat-os/core/justboot

  screen -A -m -d -S dummy sleep 22176000
  screen -S listener -X quit # kill running process
  screen -A -m -d -S listener sudo bash /home/minerstat/minerstat-os/core/init.sh
 
  #sudo systemctl stop thermald &
  #sudo systemctl disable thermald &

  #TESTLOGIN=$(timeout 2 systemctl list-jobs)
  #if [ "$TESTLOGIN" != "No jobs running." ]; then
  sudo systemctl restart systemd-logind.service &
  #fi

  # Stop and start later if needed
  #sudo systemctl stop NetworkManager &
  #sudo systemctl disable NetworkManager &

  # validate OC
  screen -A -m -d -S checkclock sudo bash /home/minerstat/minerstat-os/core/checkclock
  
  cd /home/minerstat/minerstat-os/bin
  ./shellinaboxd --port 4200 -b --css "/home/minerstat/minerstat-os/core/white-on-black.css" --disable-ssl
  
  # FIX CTRL + ALT + F1
  sudo systemctl start nvidia-persistenced &
  screen -A -m -d -S chvt sudo /home/minerstat/minerstat-os/bin/chvta

  NVIDIA="$(nvidia-smi -L)"
  AMDDEVICE=$(lsmod | grep amdgpu | wc -l)
  #if [ "$AMDDEVICE" = "0" ]; then
  #  AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
  #fi
  NVIDIADEVICE=$(lsmod | grep nvidia | wc -l)

  #echo ""
  #echo "\033[1;34m================= GPUs =================\033[0m"
  #echo "\033[1;34m== \033[1;32mAMD:\033[0m $AMDDEVICE"
  #echo "\033[1;34m== \033[1;32mNVIDIA:\033[0m $NVIDIADEVICE"
  #echo ""

  echo " "
  echo "\033[1;34m=========== NETWORK ADAPTERS ===========\033[0m"
  SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g' | xargs | wc -L)
  DHCP=$(cat /media/storage/network.txt | grep "DHCP=" | sed 's/DHCP=//g' | sed 's/"//g')

  #sudo screen -A -m -d -S restartnet sudo /etc/init.d/networking restart

  HAVECONNECTION="true"

  while ! sudo ping 1.1.1.1 -w 1 | grep "0%"; do
    HAVECONNECTION="false"
    echo "No iPV4 - running network scripts"
    break
  done

  if [ "$HAVECONNECTION" != "true" ]
  then

    #GET_GATEWAY=$(timeout 10 route -n -e -4 | awk {'print $2'} | grep -vE "0.0.0.0|IP|Gateway" | head -n1 | xargs)
    # systemd resolve casusing problems with 127.0.0.53
    #if [ ! -z "$GET_GATEWAY" ]; then
    #  sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/resolvconf/interface/systemd-resolved" 2>/dev/null
    #fi
    #sudo chmod 777 /run/resolvconf/interface/systemd-resolved 2>/dev/null
    #sudo chmod 777 /run/systemd/resolve/stub-resolv.conf 2>/dev/null
    #sudo chmod 777 /etc/resolv.conf 2>/dev/null
    #sudo su -c 'echo "nameserver 1.1.1.1" > /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    #sudo su -c 'echo "nameserver 1.0.0.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    #sudo su -c 'echo "nameserver 8.8.8.8" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    #sudo su -c 'echo "nameserver 8.8.4.4" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    #if [ ! -z "$GET_GATEWAY" ]; then
    #  sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/systemd/resolve/stub-resolv.conf" 2>/dev/null
    #fi
    #sudo su -c 'echo "nameserver 1.1.1.1" > /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    #sudo su -c 'echo "nameserver 1.0.0.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    #sudo su -c 'echo "nameserver 8.8.8.8" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    #sudo su -c 'echo "nameserver 8.8.4.4" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    #sudo su -c 'echo options edns0 >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null

    if [ "$SSID" -gt 0 ]; then
      cd /home/minerstat/minerstat-os/core
      sudo bash wifi.sh

    else

      if [ "$DHCP" != "NO" ]
      then
        cd /home/minerstat/minerstat-os/bin
        sudo bash dhcp.sh
        #sudo dhclient -v -r
      else
        cd /home/minerstat/minerstat-os/bin
        sudo bash static.sh
      fi
    fi
  fi

  # Rewrite
  #sudo systemctl stop systemd-resolved &
  #GET_GATEWAY=$(timeout 10 route -n -e -4 2>/dev/null | awk {'print $2'} 2>/dev/null | grep -vE "0.0.0.0|IP|Gateway" 2>/dev/null | head -n1 2>/dev/null | xargs 2>/dev/null)
  #sudo su -c 'echo "" > /etc/resolv.conf' 2>/dev/null
  #if [ ! -z "$GET_GATEWAY" ]; then
  #  sudo su -c "echo 'nameserver $GET_GATEWAY' >> /etc/resolv.conf" 2>/dev/null
  #fi
  #sudo su -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf' 2>/dev/null
  #sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf' 2>/dev/null
  #sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf' 2>/dev/null
  #sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf' 2>/dev/null
  # China
  #sudo su -c 'echo "nameserver 114.114.114.114" >> /etc/resolv.conf' 2>/dev/null
  #sudo su -c 'echo "nameserver 114.114.115.115" >> /etc/resolv.conf' 2>/dev/null
  # IPV6
  #sudo echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf 2>/dev/null
  #sudo echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf 2>/dev/null
  #sudo systemd-resolve --flush-caches

  sleep 1

  echo "\033[1;34m======== WAITING FOR CONNECTION ========\033[0m"
  echo ""

  # Cache management
  while ! sudo ping 104.24.98.231 -w 1 | grep "0%"; do
    sudo service network-manager restart
    sudo /usr/sbin/netplan apply
    sudo /home/minerstat/minerstat-os/core/dnser
    sleep 2
    break
  done

  echo "\033[1;34m== \033[0m Please wait ..."
  echo ""

  timeout 3 nslookup api.minerstat.com

  while ! sudo ping api.minerstat.com -w 1 | grep "0%"; do
    sudo /home/minerstat/minerstat-os/core/dnser
    sleep 2
    break
  done

  echo ""
  echo "\033[1;34m============ UPDATING msOS =============\033[0m"
  echo ""
  #sudo update-pciids
  cd /home/minerstat/minerstat-os
  sudo bash git.sh
  echo ""
  sudo chmod -R 777 /home/minerstat/minerstat-os/*
  #echo "Moving MSOS config.js to / (LINUX)"
  sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"

  echo ""
  echo "\033[1;34m===== INITIALIZING FAKE DUMMY PLUG =====\033[0m"
  echo "\033[1;34m== \033[0m Please wait ..."

  sudo killall X
  sudo killall Xorg
  sudo rm /tmp/.X0-lock
  sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
  sudo su minerstat -c "screen -A -m -d -S display2 sudo X"
  sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
  
  sleep 1
  sudo service dgm stop &
  #if [ "$NVIDIADEVICE" -gt 0 ]; then
  #  sudo su -c "sudo screen -X -S display quit" &
  #  sudo killall X
  #  sudo killall Xorg
  #  sudo kill -9 $(sudo pidof Xorg)
  #  sudo rm /tmp/.X0-lock
  #  sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
  #  sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
  #  sudo su minerstat -c "screen -A -m -d -S display2 sudo X"
  #fi
  #sudo chvt 1
  echo ""

  echo " "
  echo "\033[1;34m============ OVERCLOCKING ==============\033[0m"
  cd /home/minerstat/minerstat-os/
  sudo node stop
  sudo su minerstat -c "screen -X -S minerstat-console quit"
  echo "stop" > /tmp/stop.pid
  sudo su -c "sudo screen -X -S minew quit"
  cd /home/minerstat/minerstat-os/bin
  # PCI_BUS_ID
  if [ "$AMDDEVICE" -gt 0 ]; then
    TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
    WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"
    HWMEMORY=$(cd /home/minerstat/minerstat-os/bin/; cat amdmeminfo.txt)
    if [ -z "$HWMEMORY" ] || [ -f "/dev/shm/amdmeminfo.txt" ]; then
      HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
    fi
      sudo chmod 777 /dev/shm/amdmeminfo.txt
    if [ ! -f "/dev/shm/amdmeminfo.txt" ]; then
      sudo /home/minerstat/minerstat-os/bin/amdmeminfo -s -o -q | tac > /dev/shm/amdmeminfo.txt &
      sudo cp -rf /dev/shm/amdmeminfo.txt /home/minerstat/minerstat-os/bin
      sudo chmod 777 /home/minerstat/minerstat-os/bin/amdmeminfo.txt
      HWMEMORY=$(sudo cat /dev/shm/amdmeminfo.txt)
    fi
    sudo curl --header "Content-type: application/x-www-form-urlencoded" --request POST --data "htoken=$TOKEN" --data "hworker=$WORKER" --data "hwMemory=$HWMEMORY" "https://api.minerstat.com/v2/set_node_config_os.php"
  fi
  # MCLOCK
  echo "\033[1;34m== \033[0m Adjusting clocks in the background ..."
  #sudo chvt 1
  sudo bash /home/minerstat/minerstat-os/bin/overclock.sh

  if [ "$AMDDEVICE" -gt 0 ]; then
    echo ""
	echo "\033[1;34m========= APPLYING AMD TWEAK ===========\033[0m"
    sudo screen -A -m -d -S delaymem sh /home/minerstat/minerstat-os/bin/setmem_bg.sh
  fi

  echo " "
  echo "\033[1;34m======= INITALIZING MINERSTAT ==========\033[0m"
  cd /home/minerstat/minerstat-os
  sudo su -c "sudo screen -X -S minew quit"
  sudo su -c "sudo screen -X -S fakescreen quit"
  sudo su -c "screen -ls minew | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
  sudo su minerstat -c "screen -X -S fakescreen quit"
  screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done
  sudo su minerstat -c "screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
  sudo su minerstat -c "screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh"
  sudo rm /tmp/stop.pid > /dev/null 2>&1
  sleep 2
  sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"

  echo ""
  echo "\033[1;34m== \033[0m Minerstat started in the background ..."
  
  if grep -q experimental "/etc/lsb-release"; then
    if [ "$AMDDEVICE" -gt 0 ]; then
      echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
      echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
      sudo apt-get --yes --force-yes install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
    fi
  fi

  if [ ! -z "$NVIDIA" ]; then

    if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then

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

      if [ "$ETHPILLDELAY" != "999" ]
      then
        cd /home/minerstat/minerstat-os/bin
        sudo chmod 777 /home/minerstat/minerstat-os/bin/OhGodAnETHlargementPill-r2
        screen -A -m -d -S ethboost sudo bash ethpill.sh $ETHPILLARGS $ETHPILLDELAY
      fi

    fi
  fi

  echo " "
  echo "\033[1;34m========== INITALIZING JOBS ============\033[0m"
  cd /home/minerstat/minerstat-os/bin
  sudo bash jobs.sh $AMDDEVICE &
  echo ""

  sleep 1
  sudo chvt 1

  cd /home/minerstat/minerstat-os/core
  sudo bash expand.sh &

  echo "\033[1;34m== \033[0m Waiting for console output ..."

  # Remove pending commands
  timeout 10 curl --request POST "https://api.minerstat.com/v2/set_node_config.php?token=$TOKEN&worker=$WORKER" &

  sudo chvt 1
  sleep 1
  sudo su minerstat -c "sh /home/minerstat/minerstat-os/core/view"
  sleep 4
  exec bash
  source ~/.bashrc
fi
