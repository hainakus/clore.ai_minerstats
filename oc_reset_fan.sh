
for i in "$@"; do
nvidia-smi -i $i -pl 280
sudo nvidia-settings -a GPUFanControlState=1 -a GPUTargetFanSpeed=30
sudo nvidia-settings -a "[gpu:$i]/GPUFanControlState=1" -a "[gpu:$i]/GPUGraphicsClockOffset[3]=0" -a "[gpu:$i]/GPUMemoryTransferRateOffset[3]=0"
echo $i
done
