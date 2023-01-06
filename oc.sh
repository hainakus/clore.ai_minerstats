

for i in "$@"; do
nvidia-smi -i $i -pl 260
if [  "$i" -eq 2 ]; then
nvidia-smi -i $i -pl 240
fi
sudo nvidia-settings -a GPUFanControlState=1 -a GPUTargetFanSpeed=90 
sudo nvidia-settings -a "[gpu:$i]/GPUFanControlState=1" -a "[gpu:$i]/GPUGraphicsClockOffset[3]=75" -a "[gpu:$i]/GPUMemoryTransferRateOffset[3]=1000"
done
