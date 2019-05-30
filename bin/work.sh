if ! screen -list | grep -q "dummy"; then

  # FIX CTRL + ALT + F1
  screen -A -m -d -S chvt sudo /home/minerstat/minerstat-os/bin/chvta

  screen -A -m -d -S dummy sleep 22176000
  screen -S listener -X quit # kill running process
  screen -A -m -d -S listener sudo sh /home/minerstat/minerstat-os/core/init.sh

  # TELEPROXY
  #cd /home/minerstat/minerstat-os/bin
  #sudo su minerstat -c "screen -A -m -d -S telp sh teleconsole.sh"

  sudo find /var/log -type f -delete

  cd /home/minerstat/minerstat-os/bin
  ./shellinaboxd --port 4200 -b --css "/home/minerstat/minerstat-os/core/white-on-black.css" --disable-ssl

  # Fix Slow start bug
  sudo systemctl disable NetworkManager-wait-online.service

  NVIDIA="$(nvidia-smi -L)"
  AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
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

  while ! sudo ping minerstat.com -w 1 | grep "0%"; do
    HAVECONNECTION="false"
    break
  done


  if [ "$HAVECONNECTION" != "true" ]
  then

    sudo su -c 'echo "" > /etc/resolv.conf'
    sudo resolvconf -u
    sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
    sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf'
    sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
    sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
    # For msos versions what have local DNS cache
    sudo su -c 'echo "nameserver 127.0.0.1" >> /etc/resolv.conf'

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

  sleep 1

  echo "-------- WAITING FOR CONNECTION -----------------"
  echo ""

  # Cache management
  sudo systemd-resolve --flush-caches
  #sudo su -c "ifdown lo"
  #sudo su -c "ifup lo"

  while ! sudo ping minerstat.com -w 1 | grep "0%"; do
    sleep 1
  done

  echo ""
  echo "-------- AUTO UPDATE MINERSTAT ------------------"
  echo ""
  sudo update-pciids
  cd /home/minerstat/minerstat-os
  sudo sh git.sh
  echo ""
  sudo chmod -R 777 /home/minerstat/minerstat-os/*
  echo "Moving MSOS config.js to / (LINUX)"
  sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"

  CHECKAPT=$(dpkg -l | grep libnetpacket-perl | wc -l)

  if [ ! "$CHECKAPT" -gt "0" ]; then
    sudo apt --yes --force-yes --fix-broken install
    sudo apt-get --yes --force-yes install libnetpacket-perl  libnet-pcap-perl libnet-rawip-perl
  fi

  if grep -q experimental "/etc/lsb-release"; then
    if [ "$AMDDEVICE" -gt 0 ]; then
      echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
      echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
      sudo apt-get --yes --force-yes install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
      sudo apt-get --yes --force-yes install libcurl4
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
        CHECKAPTX=$(dpkg -l | grep cuda-libraries-10-0 | wc -l)
        if [ ! "$CHECKAPTX" -gt "0" ]; then
          # Remove OpenCl support because of NVIDIA
          sudo apt --yes --force-yes --fix-broken install
          sudo apt-get --yes --force-yes install cuda-libraries-10-0 cuda-cudart-10-0
          sudo apt-get --yes --force-yes install libcurl4
          sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
        fi
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
  sudo sh jobs.sh $AMDDEVICE
  echo ""

  sleep 1
  sudo chvt 1

  cd /home/minerstat/minerstat-os/core
  sudo sh expand.sh

  echo ""
  echo "-------- INITIALIZING FAKE DUMMY PLUG -------------"
  echo "Please wait.."
  sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0" --enable-all-gpus &
  sleep 1
  sudo service dgm stop
  sleep 3
  if [ "$NVIDIADEVICE" -gt 0 ]; then
    screen -A -m -d -S display sudo X
    screen -A -m -d -S fixer sudo chvt 1
  fi
  sudo chvt 1
  echo ""

  echo " "
  echo "-------- OVERCLOCKING ---------------------------"
  cd /home/minerstat/minerstat-os/bin
  echo "To run Overclock script manually type: mclock"
  echo "Adjusting clocks in the background.."
  sudo chvt 1
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
  sleep 2
  sudo su minerstat -c "screen -A -m -d -S minerstat-console sudo /home/minerstat/minerstat-os/launcher.sh"

  echo ""
  echo "Minerstat has been started in the background.."
  echo "Waiting for console output.."

  # Remove pending commands
  curl --request POST "https://api.minerstat.com/v2/set_node_config.php?token=$TOKEN&worker=$WORKER" &

  sleep 5
  sudo chvt 1
  sleep 9
  sudo su minerstat -c "sh /home/minerstat/minerstat-os/core/view"
  sleep 1
  exec bash
  source ~/.bashrc
fi
