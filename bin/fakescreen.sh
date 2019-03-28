#!/bin/bash

sleep 15
sudo screen -S minew -X stuff ""
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

until sudo screen -S minew -X stuff ""; do
  sleep 10
done
