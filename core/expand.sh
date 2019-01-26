DETECT="$(df -h | grep "20M" | grep "/dev/" | cut -f1 -d"2" | sed 's/dev//g' | sed 's/\///g')"
PART=$DETECT"1"
STR1="$(df -hm | grep $PART | awk '{print $2}')"
DEFAULTSIZE=7200 # MB

echo "-*- Expanding /dev/$DETECT Partition -*-"

if [ "$STR1" -gt 7300 ]; then
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
    ) | sudo fdisk /dev/$DETECT | grep "Created a new partition"
    echo ""
    sudo resize2fs /dev/$PART
    echo ""
    STR1="$(df -hm | grep $PART | awk '{print $4}')"
    echo "Free Space on the Disk: $STR1 MB"
fi
