#!/bin/bash

holidays=("2023-07-04" "2023-09-04" "2023-11-23" "2023-12-25" "2024-01-01")
today=`date -I`
sleep=21600
awake=`date -d "+$((sleep/3600)) hours"`

if [[ ! " ${holidays[*]} " =~ " ${today} " ]]; then
   logger "Today is TOU day. Stopping minner and rebooting $awake"
   miner stop && sreboot wakealarm $sleep
fi
