#!/bin/sh

DRIVE_NUMBER=$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g')
DRIVE_PARTITION=$DRIVE_NUMBER"1"
DRIVE_EFI=$DRIVE_NUMBER"3"
#echo $DRIVE_NUMBER
#PARTITION_MAX_SIZE_IN_GB=$(lsblk | grep $DRIVE_PARTITION | grep part | head -n 1 | awk '{print $4}' | sed 's/[^.0-9]*//g')
#sudo cat /proc/partitions | grep $DRIVE_NUMBER | head -n1 | awk '{print $3}'
PARTITION_MAX_SIZE_IN_BYTE=$(sudo cat /proc/partitions | grep $DRIVE_NUMBER | head -n1 | awk '{print $3}')
PARTITION_MAX_SIZE_IN_MB=$(python -c "print $PARTITION_MAX_SIZE_IN_BYTE / 1024")
CURRENT_PARTITION_SIZE_IN_BYTE=$(sudo cat /proc/partitions | grep $DRIVE_NUMBER"1" | head -n1 | awk '{print $3}')
CURRENT_PARTITION_SIZE_IN_MB=$(python -c "print $CURRENT_PARTITION_SIZE_IN_BYTE / 1024")
#CURRENT_PARTITION_SIZE_IN_GB=$(df -h | grep $DRIVE_PARTITION | awk '{print $2}' | sed 's/[^.0-9]*//g')
#CURRENT_PARTITION_SIZE_IN_MB=$(python -c "print $CURRENT_PARTITION_SIZE_IN_GB * 1024")
SIZE_DIFFERENCE=$(python -c "print $PARTITION_MAX_SIZE_IN_MB - $CURRENT_PARTITION_SIZE_IN_MB" | cut -f1 -d".") # 0.1 x 1000 = 100Mb

#echo $PARTITION_MAX_SIZE_IN_BYTE
echo "Drive max size: $PARTITION_MAX_SIZE_IN_MB Mb"
#echo $CURRENT_PARTITION_SIZE_IN_GB
echo "Current max size: $CURRENT_PARTITION_SIZE_IN_MB"
echo "Difference in size: $SIZE_DIFFERENCE"

echo "-*- Expanding /dev/$DRIVE_PARTITION Partition -*-"

# Keep 300Mb difference between drive and partition size for check
if [ "$SIZE_DIFFERENCE" -lt "300" ]; then
  RESIZED="RESIZED"
else
  RESIZED="NEED"
fi

if [ "$RESIZED" = "RESIZED" ]; then
    echo "=== ALREADY RESIZED ==="
else
    if grep -q experimental "/etc/lsb-release"; then
        EFI=$(sudo cat /proc/partitions | grep "$DRIVE_EFI" | awk '{print $3}')
        #echo $EFI
        if [ "$EFI" = "44032" ]; then
          if [ "$SIZE_DIFFERENCE" -gt "600" ]; then

            LIST_FREE_SECTORS=$(echo 'F' | sudo fdisk /dev/sda)
            FREE_SECTORS=${LIST_FREE_SECTORS##*Size}
            FREE_SPACE_END=$(echo $FREE_SECTORS | awk '{print $2}')
            FIRST_SECTOR=$(python -c "print $FREE_SPACE_END - 88064")

            echo "Free Space Last Sector: $FREE_SPACE_END"
            echo "Target Sector for EFI: $FIRST_SECTOR"

              if [ -z "$FIRST_SECTOR" ]; then 
                echo "Moving EFI Partition to END of the Drive"
#               sudo umount /dev/$DRIVE_EFI
#               (
#                 echo d # Delete partition
#                 echo 3 # Delete EFI
#                 echo n # New partition
#                 echo p # Primary
#                 echo 3 # EFI PARTition
#                 echo $FIRST_SECTOR # First sector (Accept default: 1)
#                 echo   # Last sector (Accept default: varies)
#                 echo w # Write changes
#                ) | sudo fdisk /dev/$DRIVE_NUMBER
              fi

            fi
        fi
    fi
    echo "=== RESIZING ==="
    (
        echo d # Delete partition
        echo 1 # Delete first
        echo n # New partition
        echo p # Primary
        echo 1 # 1 Partition
        echo   # First sector (Accept default: 1)
        echo   # Last sector (Accept default: varies)
        echo w # Write changes
    ) | sudo fdisk /dev/$DRIVE_NUMBER | grep "Created a new partition"
    sudo growpart "/dev/$DRIVE_NUMBER" 1
    echo ""
    sudo resize2fs /dev/$DRIVE_PARTITION
    echo ""
    CURRENT_FREE_SPACE_IN_MB="$(df -hm | grep $DRIVE_PARTITION | awk '{print $4}')"
    echo "Free Space on the Disk: $CURRENT_FREE_SPACE_IN_MB MB"
fi
