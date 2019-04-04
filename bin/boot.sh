if ! screen -list | grep -q "dummy"; then

    screen -A -m -d -S dummy sleep 86400
    screen -S listener -X quit # kill running process
    screen -A -m -d -S listener sudo sh /home/minerstat/minerstat-os/core/init.sh

    sudo echo "boot" > /home/minerstat/minerstat-os/bin/random.txt
    sudo find /var/log -type f -delete

    # Fix Slow start bug
    sudo systemctl disable NetworkManager-wait-online.service

    # FIX CTRL + ALT + F1
    screen -A -m -d -S chvt sudo watch -n1 sudo chvt 1

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

    sudo su -c 'echo "" > /etc/resolv.conf'
	sudo resolvconf -u
	sudo su -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
	sudo su -c 'echo "nameserver 1.0.0.1" >> /etc/resolv.conf'
	sudo su -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
	sudo su -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

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


    CHECKAPT=$(dpkg -l | grep libnetpacket-perl | wc -l)

    if [ ! "$CHECKAPT" -gt "0" ]; then
        sudo apt --yes --force-yes --fix-broken install
        sudo apt-get --yes --force-yes install libnetpacket-perl  libnet-pcap-perl libnet-rawip-perl
    fi

    #########################
    # <IF EXPERIMENTAL
    if grep -q experimental "/etc/lsb-release"; then

      AMDDEVICE=$(sudo lshw -C display | grep AMD | wc -l)
      if [ "$AMDDEVICE" -gt 0 ]; then
        echo "INFO: Seems you have AMD Device enabled, activating OpenCL Support."
        echo "INFO: Nvidia / AMD Mixing not supported. If you want to use OS on another rig, do mrecovery."
        sudo apt-get --yes --force-yes install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
      fi

      # Solve AMDGPU XORG bug
      NVIDIA="$(nvidia-smi -L)"
      if [ ! -z "$NVIDIA" ]; then
        if echo "$NVIDIA" | grep -iq "^GPU 0:" ;then
          # Solves NVIDIA-SETTINGS OC ISSUE
          # amdgpu_device_initialize: amdgpu_get_auth (1) failed (-1)
          sudo apt --yes --force-yes --fix-broken install
          sudo apt-get --yes --force-yes install cuda-libraries-10-0 cuda-cudart-10-0
          sudo apt-get --yes --force-yes install libcurl4
          sudo dpkg --remove --force-all libegl1-amdgpu-pro:i386 libegl1-amdgpu-pro:amd64
          # To enable back AMD-OpenCL
          # sudo apt-get install libegl1-amdgpu-pro:amd64 libegl1-amdgpu-pro:i386
        fi
      fi

    fi
    # />
    #########################

    echo ""
    echo "-------- INSTALLING FAKE DUMMY PLUG ------------"
    echo "Please wait.."
    sleep 1
    #sudo update-grub
    sudo nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0" --enable-all-gpus
    sudo service gdm stop >/dev/null
    #screen -A -m -d -S display sudo X
    sleep 5

    sudo chvt 1

    echo ""


    echo "-------- REBOOT IN 3 SEC -----------"
    sleep 2
    sudo reboot -f
fi
