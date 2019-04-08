#!/bin/bash
exec 2>/dev/null

if [ ! -z "$2" ]; then
  echo "ETHPILL DELAY: $2"
  sleep $2
else
  echo "ETHPILL DELAY: 10"
  sleep 10
fi

sudo /home/minerstat/minerstat-os/bin/OhGodAnETHlargementPill-r2 $1
