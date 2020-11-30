#!/bin/bash

# Args
FORCE=$(cat /home/minerstat/flash.json | /home/minerstat/minerstat-os/bin/jq -r .force)
REBOOT=$(cat /home/minerstat/flash.json | /home/minerstat/minerstat-os/bin/jq -r .reboot)
ROM=$(cat /home/minerstat/flash.json | /home/minerstat/minerstat-os/bin/jq -r .rom)
GPUS=$(cat /home/minerstat/flash.json | /home/minerstat/minerstat-os/bin/jq -r .gpus | /home/minerstat/minerstat-os/bin/jq -r .[] | xargs)

# Auth
TOKEN="$(cat /media/storage/config.js | grep 'global.accesskey' | sed 's/global.accesskey =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g' | sed 's/[^a-zA-Z0-9]*//g')"
WORKER="$(cat /media/storage/config.js | grep 'global.worker' | sed 's/global.worker =//g' | sed 's/;//g' | sed 's/ //g' | sed 's/"//g' | sed 's/\\r//g')"
SID=$(cat /home/minerstat/flash.json | /home/minerstat/minerstat-os/bin/jq -r .id)

# Flasher
FLASHER="amdvbflash"
FAILED=0

# Info
echo
echo "========== ARGS ============="
echo "Force: $FORCE"
echo "Reboot: $REBOOT"
echo "GPUS: $GPUS"
echo "============================="
echo

# Folders
sudo mkdir /home/minerstat/bios > /dev/null 2>&1
sudo mkdir /home/minerstat/bios/backups > /dev/null 2>&1
sudo mkdir /home/minerstat/bios/flashed > /dev/null 2>&1

# Path
DATE=$(date '+%Y%m%d%H%M%S')
BIOS="$DATE-bios.rom"
PATHS="/home/minerstat/bios/flashed/$BIOS"

# Save
echo "Validating .rom ..."
echo -n "$ROM" | sudo /usr/bin/base64 --decode > $PATHS
sleep 0.5

# Validate
PN=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -biosfileinfo /home/minerstat/bios/flashed/20201128211914-bios.rom | tr -d '\040\011\015' | grep "P/N" | sed 's/.*://g')
PROD=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -biosfileinfo /home/minerstat/bios/flashed/20201128211914-bios.rom | tr -d '\040\011\015' | grep "Product" | sed 's/.*://g')
DID=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -biosfileinfo /home/minerstat/bios/flashed/20201128211914-bios.rom | tr -d '\040\011\015' | grep "DeviceID" | sed 's/.*://g')

echo
echo "============================="
echo "Bios PN:      $PN"
echo "Bios Product: $PROD"
echo "Bios DID:     $DID"
echo "Bios queue:   $PATHS"
echo "============================="
echo

if [[ $PROD == *"Polaris"* ]] || [[ $PROD == *"Ellesmere"* ]]; then
  FLASHER="atiflash"
fi

if [[ ! -z "$PN" ]] && [[ ! -z "$PROD" ]] && [[ ! -z "$DID" ]]; then
  echo "Bios looks valid"
  # Stop mining, maintenance mode etc..
  echo "Going to Idle mode"
  sudo /home/minerstat/minerstat-os/core/stop >/dev/null 2>&1
  echo "Entering maintanance mode"
  sudo /home/minerstat/minerstat-os/core/maintenance >/dev/null 2>&1
  echo "Killing Xorg"
  sudo killall X sudo killall Xorg sudo killall Xorg >/dev/null 2>&1
  # Loop GPU List
  for bus in $GPUS; do
    echo
    echo "========== $bus =========="
    GPUBUSINT=$(echo $bus | cut -f 1 -d '.')
    GPUBUS=$(python -c 'print(int("'$GPUBUSINT'", 16))')
    echo "GPU: $bus"
    echo "GPU BUS SHORT: $GPUBUSINT"
    echo "GPU BUS INT: $GPUBUS"
    CHECK_SUPPORT=""
    if [[ "$FLASHER" = "atiflash" ]]; then
      CHECK_SUPPORT=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -i | awk {'print $2'} | grep -c -i "$GPUBUSINT")
    else
      CHECK_SUPPORT=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -i | awk {'print $3'} | grep -c -i "$GPUBUSINT")
    fi
    if [[ "$CHECK_SUPPORT" -gt 0 ]]; then
      echo "Validation: $bus is listed within the flasher"
      BUS_ID=""
      if [[ "$FLASHER" = "atiflash" ]]; then
        BUS_ID=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -i | awk '{print $1, $2}' | grep -i "$GPUBUSINT" | awk {'print $1'})
      else
        BUS_ID=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -i | awk '{print $1, $3}' | grep -i "$GPUBUSINT" | awk {'print $1'})
      fi
      echo "ADAPTER ID: $BUS_ID"
      BIOS="$DATE-$GPUBUSINT-bios.rom"
      PATHS="/home/minerstat/bios/backups/$BIOS"
      echo "Bios saving:   $PATHS"
      BACKUP=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -s $BUS_ID $PATHS)
      if [[ $BACKUP == *"bytes saved"* ]]; then
        echo "$BACKUP"
        echo "Bios saved:   $PATHS"
        # Flashing new rom
        BIOS="$DATE-bios.rom"
        PATHS="/home/minerstat/bios/flashed/$BIOS"
        # Start flashing
        STATUS="flashing"
        curl --insecure --connect-timeout 20 --max-time 25 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "bus=$bus" --data "id=$SID" --data "status=$STATUS" "https://api.minerstat.com:2053/v2/setflash.php" > /dev/null 2>&1
        # Check force
        FLASHLOG=""
        if [[ "$FORCE" = "1" ]]; then
          echo "Preparing to FORCE flash $PATHS to device ID $BUS_ID [BUS: $bus]"
          FLASHLOG=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -f -p $BUS_ID $PATHS)
          echo $FLASHLOG
        else
          echo "Preparing to flash $PATHS to device ID $BUS_ID [BUS: $bus]"
          FLASHLOG=$(sudo /home/minerstat/minerstat-os/bin/$FLASHER -p $BUS_ID $PATHS)
          echo $FLASHLOG
        fi
        # Verify flash
        if [[ $FLASHLOG == *"bytes programmed"* ]] && [[ $FLASHLOG == *"bytes verified"* ]]; then
          STATUS="success"
        else
          if [[ $FLASHLOG == *"Flash already programmed"* ]]; then
            STATUS="force"
            FAILED=$((FAILED+1))
          else
            STATUS="failed"
            FAILED=$((FAILED+1))
          fi
        fi
        # Send status
        curl --insecure --connect-timeout 20 --max-time 25 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "bus=$bus" --data "id=$SID" --data "status=$STATUS" "https://api.minerstat.com:2053/v2/setflash.php" > /dev/null 2>&1
      else
        echo "Something went wrong during making a backup of current .rom, not flashing new one without backup"
      fi
    else
      echo "Error: $bus not listed within flasher"
    fi
    echo "============================="
    echo
  done

  ## Sync to disk
  curl --insecure --connect-timeout 20 --max-time 25 --header "Content-type: application/x-www-form-urlencoded" --request POST --data "token=$TOKEN" --data "worker=$WORKER" --data "bus=" --data "id=$SID" --data "status=done" "https://api.minerstat.com:2053/v2/setflash.php" > /dev/null 2>&1
  sync

  if [[ "$REBOOT" = "1" ]]; then
    echo "Reboot was requested, validating"
    if [[ "$FAILED" = 0 ]]; then
      echo "Everything went fine, rebooting"
      sudo bash /home/minerstat/minerstat-os/bin/reboot.sh
    else
      echo "Something went wrong during flash, reboot not allowed"
    fi
  else
    echo "Reboot was not requested, skipping"
  fi
else
  echo "Bios invalid, flashing skipped"
fi
