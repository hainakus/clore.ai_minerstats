if ! screen -list | grep -q "dummy"; then

    screen -A -m -d -S dummy sleep 86400

    sudo echo "boot" > /home/minerstat/minerstat-os/bin/random.txt
    sudo find /var/log -type f -delete

    # Fix Slow start bug
    sudo systemctl disable NetworkManager-wait-online.service

    echo ""
    echo "-------- INSTALLING FAKE DUMMY PLUG ------------"
    echo "Please wait.."
    sleep 1
    #sudo update-grub
    sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0" --enable-all-gpus
    sudo service gdm stop >/dev/null
    #screen -A -m -d -S display sudo X
    sleep 5

    # FIX CTRL + ALT + F1
    screen -A -m -d -S chvt sudo watch -n1 sudo chvt 1
    sudo chvt 1

    echo ""

    #echo "-------- OVERCLOCKING ---------------------------"
    #cd /home/minerstat/minerstat-os/bin
    #sudo sh overclock.sh

    # Change hostname
    #WNAME=$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =/"/g' | sed 's/"//g' | sed 's/;//g' | xargs)
    #sudo su -c "echo '$WNAME' > /etc/hostname"
    #sudo hostname -F /etc/hostname

    echo " "
    echo "-------- CONFIGURE NETWORK ADAPTERS --------------"
    SSID=$(cat /media/storage/network.txt | grep 'WIFISSID="' | sed 's/WIFISSID="//g' | sed 's/"//g' | xargs | wc -L)
    DHCP=$(cat /media/storage/network.txt | grep 'DHCP="' | sed 's/DHCP="//g' | sed 's/"//g')

    #sudo screen -A -m -d -S restartnet sudo /etc/init.d/networking restart

    HAVECONNECTION="true"

    while ! sudo ping minerstat.com -w 1 | grep "0%"; do
        HAVECONNECTION="false"
        break
    done


    if [ "$HAVECONNECTION" != "true" ]
    then


      if [ "$SSID" -gt 0 ]; then
          cd /home/minerstat/minerstat-os/core
          sudo sh wifi.sh

      else

          if [ "$DHCP" != "NO" ]
          then
              cd /home/minerstat/minerstat-os/bin
              sudo sh dhcp.sh
          else
              cd /home/minerstat/minerstat-os/bin
              sudo sh static.sh
          fi

      fi


    fi

    sleep 1

    echo "-------- WAITING FOR CONNECTION -----------------"
    echo ""

    while ! sudo ping minerstat.com -w 1 | grep "0%"; do
        sleep 1
    done

    echo ""
    echo "-------- AUTO UPDATE MINERSTAT ------------------"
    echo ""
    cd /home/minerstat/minerstat-os
    sudo sh git.sh
    echo ""

    echo "-------- RUNNING JOBS ---------------------------"
    cd /home/minerstat/minerstat-os/bin
    sudo sh jobs.sh
    echo ""

    cd /home/minerstat/minerstat-os/core
    sudo sh expand.sh


    if [ "$SSID" -gt 0 ]; then
        cd /home/minerstat/minerstat-os/core
        sudo sh wifi.sh

    else

        if [ "$DHCP" != "NO" ]
        then
            cd /home/minerstat/minerstat-os/bin
            sudo sh dhcp.sh
        else
            cd /home/minerstat/minerstat-os/bin
            sudo sh static.sh
        fi

    fi


    #########################
    # <IF EXPERIMENTAL
    if grep -q experimental "/etc/lsb-release"; then

      AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
      if [ "$AMDDEVICE" -gt 0 ]; then
        echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
        echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
        sudo apt-get install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
      fi

      # Solve AMDGPU XORG bug
      NVIDIA="$(nvidia-smi -L)"
      if [ ! -z "$NVIDIA" ]; then
        if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
          # Solves NVIDIA-SETTINGS OC ISSUE
          # amdgpu_device_initialize: amdgpu_get_auth (1) failed (-1)
          sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
          # To enable back AMD-OpenCL
          # sudo apt-get install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
        fi
      fi

    fi
    # />
    #########################


    echo "-------- REBOOT IN 3 SEC -----------"
    sleep 2
    sudo reboot -f
fi
