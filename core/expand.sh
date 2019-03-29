#!/bin/sh

DRIVE_NUMBER=$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g')
DRIVE_PARTITION=$DRIVE_NUMBER"1"
DRIVE_MAX_SIZE_IN_GB=$(lsblk | grep sdc | grep disk | awk '{print $4}' | sed 's/[^.0-9]*//g')
PARTITION_MAX_SIZE_IN_GB=$(lsblk | grep sdc | grep part | head -n 1 | awk '{print $4}' | sed 's/[^.0-9]*//g')
SIZE_DIFFERENCE=$(python -c "print ($DRIVE_MAX_SIZE_IN_GB - $PARTITION_MAX_SIZE_IN_GB) * 1000" | cut -f1 -d".") # 0.1 x 1000 = 100Mb

echo "-*- Expanding /dev/$DRIVE_PARTITION Partition -*-"

# Keep 200Mb difference between drive and partition size for check
if [ "$SIZE_DIFFERENCE" -lt "200" ]; then
  RESIZED="RESIZED"
else
  RESIZED="NEED"
fi

if [ "$RESIZED" = "RESIZED" ]; then
    echo "=== ALREADY RESIZED ==="
else
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
    echo ""
    sudo resize2fs /dev/$DRIVE_PARTITION
    echo ""
    CURRENT_FREE_SPACE_IN_MB="$(df -hm | grep $DRIVE_PARTITION | awk '{print $4}')"
    echo "Free Space on the Disk: $CURRENT_FREE_SPACE_IN_MB MB"
fi
