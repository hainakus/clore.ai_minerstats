if ! screen -list | grep -q "dummy"; then

    screen -A -m -d -S dummy sleep 22176000

    # FIX CTRL + ALT + F1
    screen -A -m -d -S chvt sudo watch -n1 sudo chvt 1

    sudo find /var/log -type f -delete

    cd /home/minerstat/minerstat-os/bin
    ./shellinaboxd --port 4200 -b --css "/home/minerstat/shellinabox/shellinabox/white-on-black.css" --disable-ssl

    # Fix Slow start bug
    sudo systemctl disable NetworkManager-wait-online.service

    NVIDIA="$(nvidia-smi -L)"

    echo ""
    echo "-------- INITIALIZING FAKE DUMMY PLUG -------------"
    echo "Please wait.."
    sleep 1
    sudo service dgm stop
    sleep 3
    screen -A -m -d -S display sudo X
    echo ""

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
    DHCP=$(cat /media/storage/network.txt | grep 'DHCP="' | sed 's/DHCP="//g' | sed 's/"//g')

    #sudo screen -A -m -d -S restartnet sudo /etc/init.d/networking restart

    HAVECONNECTION="true"

    while ! sudo ping minerstat.com -w 1 | grep "0%"; do
        HAVECONNECTION="false"
        break
    done


    if [ "$HAVECONNECTION" != "true" ]
    then

    sudo resolvconf -u
    
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
    sudo update-pciids
    cd /home/minerstat/minerstat-os
    #sudo sh git.sh
    echo ""
    sudo chmod -R 777 /home/minerstat/minerstat-os/*
    echo "Moving MSOS config.js to / (LINUX)"
    sudo cp -rf "/media/storage/config.js" "/home/minerstat/minerstat-os/"

    if grep -q experimental "/etc/lsb-release"; then
      if [ "$AMDDEVICE" -gt 0 ]; then
        echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
        echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
        sudo apt-get install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386 --fix-broken
      fi
    fi

    if [ ! -z "$NVIDIA" ]; then

        if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then

            ETHPILLARGS=$(cat /media/storage/settings.txt 2>/dev/null | grep 'OHGODARGS="' | sed 's/OHGODARGS="//g' | sed 's/"//g')
            ETHPILLDELAY=$(cat /media/storage/settings.txt 2>/dev/null | grep 'OHGODADELAY=' | sed 's/[^0-9]*//g')

          if grep -q experimental "/etc/lsb-release"; then
            # Remove OpenCl support because of NVIDIA
            sudo apt-get install cuda-libraries-10-0 cuda-cudart-10-0 --fix-broken
            sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
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
    echo "-------- OVERCLOCKING ---------------------------"
    cd /home/minerstat/minerstat-os/bin
    echo "To run Overclock script manually type: mclock"
    echo "Adjusting clocks in the background.."
    sudo sh /home/minerstat/minerstat-os/bin/overclock.sh

    echo " "
    echo "-------- RUNNING JOBS ---------------------------"
    screen -A -m -d -S listener sudo sh /home/minerstat/minerstat-os/core/init.sh
    cd /home/minerstat/minerstat-os/bin
    sudo sh jobs.sh
    echo ""

    sleep 1
    sudo chvt 1

    cd /home/minerstat/minerstat-os/core
    sudo sh expand.sh

    echo " "
    echo "-------- INITALIZING MINERSTAT CLIENT -----------"
    cd /home/minerstat/minerstat-os
    screen -A -m -d -S minerstat-console sh /home/minerstat/minerstat-os/start.sh;
    echo ""
    echo "Minerstat has been started in the background.."
    echo "Waiting for console output.."

    sleep 5
    sudo chvt 1
    sleep 9
    screen -x minerstat-console
    sleep 1
    exec bash
    source ~/.bashrc
fi
