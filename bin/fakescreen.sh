#!/bin/bash

sleep 15
tmux send-keys "" Enter;
tmux send-keys "" Enter;
tmux send-keys "" Enter;
screen -S minerstat-console -X stuff "s"
tmux send-keys "" Enter;
sleep 1
tmux send-keys "" Enter;
sleep 1
tmux send-keys "" Enter;
sleep 5
tmux send-keys "" Enter;
tmux send-keys "" Enter;
tmux send-keys "" Enter;
screen -S minerstat-console -X stuff "s"
screen -S minerstat-console -X stuff "s"
tmux send-keys "" Enter;
tmux send-keys "" Enter;
sleep 1
tmux send-keys "" Enter;