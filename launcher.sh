#!/bin/bash

tmux \
    new-session 'cd /home/minerstat/minerstat-os/; node --max-old-space-size=512 start' \; \
    resize-pane -U 5 \; \
    send-keys C-a M-3 \;
