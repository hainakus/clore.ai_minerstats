if ! screen -list | grep -q "dummy"; then
  screen -A -m -d -S dummy sleep 22176000
  screen -S listener -X quit # kill running process
  screen -A -m -d -S listener sudo sh /home/minerstat/minerstat-os/core/init.sh

  # validate OC
  screen -A -m -d -S checkclock sudo bash /home/minerstat/minerstat-os/core/checkclock
  
  cd /home/minerstat/minerstat-os/bin
  ./shellinaboxd --port 4200 -b --css "/home/minerstat/minerstat-os/core/white-on-black.css" --disable-ssl
  
  # FIX CTRL + ALT + F1
  sudo systemctl start nvidia-persistenced &
  screen -A -m -d -S chvt sudo /home/minerstat/minerstat-os/bin/chvta

  # TELEPROXY
  #cd /home/minerstat/minerstat-os/bin
  #sudo su minerstat -c "screen -A -m -d -S telp sh teleconsole.sh"

  sudo find /var/log -type f -delete

  NVIDIA="$(nvidia-smi -L)"
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
  if [ "$AMDDEVICE" = "0" ]; then
    AMDDEVICE=$(sudo lshw -C display | grep driver=amdgpu | wc -l)
  fi
  NVIDIADEVICE=$(sudo lshw -C display | grep NVIDIA | wc -l)

  echo ""
  echo "-------- GRAPHICS CARDS -------------"
  echo "FOUND AMD    :  $AMDDEVICE"
  echo "FOUND NVIDIA :  $NVIDIADEVICE"
  echo ""

  echo " "
  echo "-------- CONFIGURE NETWORK ADAPTERS --------------"
  SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g' | xargs | wc -L)
  DHCP=$(cat /media/storage/network.txt | grep "DHCP=" | sed 's/DHCP=//g' | sed 's/"//g')

  #sudo screen -A -m -d -S restartnet sudo /etc/init.d/networking restart

  HAVECONNECTION="true"

  while ! sudo ping 1.1.1.1 -w 1 | grep "0%"; do
    HAVECONNECTION="false"
    break
  done

  if [ "$HAVECONNECTION" != "true" ]
  then

    GET_GATEWAY=$(timeout 10 route -n -e -4 | awk {'print $2'} | grep -vE "0.0.0.0|IP|Gateway" | head -n1 | xargs)
    # systemd resolve casusing problems with 127.0.0.53
    if [ ! -z "$GET_GATEWAY" ]; then
      sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/resolvconf/interface/systemd-resolved" 2>/dev/null
    fi
    sudo su -c 'echo "nameserver 1.1.1.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    sudo su -c 'echo "nameserver 1.0.0.1" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    sudo su -c 'echo "nameserver 8.8.8.8" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    sudo su -c 'echo "nameserver 8.8.4.4" >> /run/resolvconf/interface/systemd-resolved' 2>/dev/null
    if [ ! -z "$GET_GATEWAY" ]; then
      sudo su -c "echo 'nameserver $GET_GATEWAY' > /run/systemd/resolve/stub-resolv.conf" 2>/dev/null
    fi
    sudo su -c 'echo "nameserver 1.1.1.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    sudo su -c 'echo "nameserver 1.0.0.1" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    sudo su -c 'echo "nameserver 8.8.8.8" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    sudo su -c 'echo "nameserver 8.8.4.4" >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null
    sudo su -c 'echo options edns0 >> /run/systemd/resolve/stub-resolv.conf' 2>/dev/null

    if [ "$SSID" -gt 0 ]; then
      cd /home/minerstat/minerstat-os/core
      sudo sh wifi.sh

    else

      if [ "$DHCP" != "NO" ]
      then
        cd /home/minerstat/minerstat-os/bin
        sudo sh dhcp.sh
        #sudo dhclient -v -r
      else
        cd /home/minerstat/minerstat-os/bin
        sudo sh static.sh
      fi
    fi
  fi

  # Rewrite
  sudo systemctl stop systemd-resolved
  GET_GATEWAY=$(timeout 10 route -n -e -4 | awk {'print $2'} | grep -vE "0.0.0.0|IP|Gateway" | head -n1 | xargs)
  sudo su -c 'echo "" > /etc/resolv.conf' 2>/dev/null
  if [ ! -z "$GET_GATEWAY" ]; then
    sudo su -c "echo 'nameserver $GET_GATEWAY' >> /etc/resolv.conf" 2>/dev/null
  fi
  sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf' 2>/dev/null
  sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf' 2>/dev/null
  sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf' 2>/dev/null
  sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf' 2>/dev/null
  # China
  sudo su -c 'echo "nameserver 114.114.114.114" >> /etc/resolv.conf' 2>/dev/null
  sudo su -c 'echo "nameserver 114.114.115.115" >> /etc/resolv.conf' 2>/dev/null
  # IPV6
  sudo su -c 'echo nameserver 2606:4700:4700::1111 >> /etc/resolv.conf' 2>/dev/null
  sudo su -c 'echo nameserver 2606:4700:4700::1001 >> /etc/resolv.conf' 2>/dev/null
  sudo systemd-resolve --flush-caches

  sleep 1

  echo "-------- WAITING FOR CONNECTION -----------------"
  echo ""

  # Cache management
  while ! sudo ping minerstat.com. -w 1 | grep "0%"; do
    sudo service network-manager restart
    sudo /usr/sbin/netplan apply
    break
  done
  #sudo su -c "ifdown lo"
  #sudo su -c "ifup lo"

  echo "Waiting for DNS resolve.."
  echo "It can take a few moments! You may see ping messages for a while"
  echo ""

  nslookup api.minerstat.com

  while ! sudo ping api.minerstat.com. -w 1 | grep "0%"; do
    sudo /home/minerstat/minerstat-os/core/dnser
    sleep 3
  done

  echo ""
  echo "-------- AUTO UPDATE MINERSTAT ------------------"
  echo ""
  #sudo update-pciids
  cd /home/minerstat/minerstat-os
  sudo sh git.sh
  echo ""
  sudo chmod -R 777 /home/minerstat/minerstat-os/*
  echo "Moving MSOS config.js to / (LINUX)"
  sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"

  echo ""
  echo "-------- INITIALIZING FAKE DUMMY PLUG -------------"
  echo "Please wait.."

  sudo killall X
  sudo killall Xorg
  sudo rm /tmp/.X0-lock
  sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
  sudo su minerstat -c "screen -A -m -d -S display2 sudo X"
  sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
  
  sleep 1
  sudo service dgm stop
  sleep 3
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    sudo su -c "sudo screen -X -S display quit" &
    sudo killall X
    sudo killall Xorg
    sudo kill -9 $(sudo pidof Xorg)
    sudo rm /tmp/.X0-lock
    sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
    sudo sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
    sudo su minerstat -c "screen -A -m -d -S display2 sudo X"
  fi
  sudo chvt 1
  echo ""

  echo " "
  echo "-------- OVERCLOCKING ---------------------------"
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
  echo "To run Overclock script manually type: mclock"
  echo "Adjusting clocks in the background.."
  #sudo chvt 1
  sudo sh /home/minerstat/minerstat-os/bin/overclock.sh

  if [ "$AMDDEVICE" -gt 0 ]; then
    echo ""
    echo "--- Apply Strap (AMD TWEAK) from DB ---"
    sudo screen -A -m -d -S delaymem sh /home/minerstat/minerstat-os/bin/setmem_bg.sh
  fi

  echo " "
  echo "-------- INITALIZING MINERSTAT CLIENT -----------"
  cd /home/minerstat/minerstat-os
  sudo su -c "sudo screen -X -S minew quit"
  sudo su -c "sudo screen -X -S fakescreen quit"
  sudo su -c "screen -ls minew | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
  sudo su minerstat -c "screen -X -S fakescreen quit"
  screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done
  sudo su minerstat -c "screen -ls minerstat-console | grep -E '\s+[0-9]+\.' | awk -F ' ' '{print $1}' | while read s; do screen -XS $s quit; done"
  sudo su minerstat -c "screen -A -m -d -S fakescreen sh /home/minerstat/minerstat-os/bin/fakescreen.sh"
  sudo rm /tmp/stop.pid
  sleep 2
  sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"

  echo ""
  echo "Minerstat has been started in the background.."

  
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
        screen -A -m -d -S ethboost sudo sh ethpill.sh $ETHPILLARGS $ETHPILLDELAY
      fi

    fi
  fi

  echo " "
  echo "-------- RUNNING JOBS ---------------------------"
  cd /home/minerstat/minerstat-os/bin
  sudo sh jobs.sh $AMDDEVICE &
  echo ""

  sleep 1
  sudo chvt 1

  cd /home/minerstat/minerstat-os/core
  sudo sh expand.sh &

  echo "Waiting for console output.."

  # Remove pending commands
  curl --request POST "https://api.minerstat.com/v2/set_node_config.php?token=$TOKEN&worker=$WORKER" &

  sleep 3
  sudo chvt 1
  sleep 3
  sudo su minerstat -c "sh /home/minerstat/minerstat-os/core/view"
  sleep 1
  exec bash
  source ~/.bashrc
fi
