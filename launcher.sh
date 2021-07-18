#!/bin/bash

if [ -f "/dev/shm/maintenance.pid" ]; then
  echo "Miner not started, maintenance enabled"
else
  sudo nvidia-settings -a GPUPowerMizerMode=1 -c :0 2>&1 >/dev/null

  tmux \
    new-session 'cd /home/minerstat/minerstat-os/; node --max-old-space-size=384 start' \; \
    resize-pane -U 5 \; \
    send-keys C-a M-3 \;
fi
