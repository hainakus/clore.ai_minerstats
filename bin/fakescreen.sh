#!/bin/bash

sleep 15
sudo screen -S minew -X stuff ""

until sudo screen -S minew -X stuff ""; do
  sleep 10
done
