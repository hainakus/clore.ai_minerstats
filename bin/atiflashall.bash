#!/bin/bash
#exec 2>/dev/null

AMDN=$(sudo lshw -C display | grep AMD | wc -l)
BIOS=$1
ARG2=$2

echo "====== ATIFLASHER ======="

if [ "$AMDDEVICE" != 0 ]
then
	echo ""
	else
	echo "No AMD GPU's detected"
	exit 1
fi

if [ "$BIOS" != "" ]
then
	echo ""
else
	echo "Flash VBIOS to all AMD GPUs on the system"
	echo "You need to upload your .rom file to /home/minerstat/minerstat-os/bin (SFTP)"
	echo "Usage: mflashall bios.rom";
	echo "To force the flash use: mflashall bios.rom -f"
	exit 1
fi

cd /home/minerstat/minerstat-os/bin

sudo ./atiflash -i
echo ""

for (( i=0; i < $AMDN; i++ )); do
	echo "--- Flashing GPU$i ---"
	if [ "$ARG2" != "-f" ]
	then
		sudo ./atiflash -p $i $BIOS
	else
		sudo ./atiflash -p -f $i $BIOS
	fi
done

sudo ./atiflash -i

echo ""
echo "------ FLASH DONE -------"
echo "Reboot to apply changes"
echo "======  Done   ========="
