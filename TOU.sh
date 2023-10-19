#!/bin/bash

SESSION='Mining'
TREX='T-Rex'
RAPT='Raptoreum'
CHIA='Chia'
holidays=("2023-07-04" "2023-09-04" "2023-11-23" "2023-12-25" "2024-01-01")
today=`date -I`
sleep=21600
awake=`date -d "+$((sleep/3600)) hours"`

if [[ ! " ${holidays[*]} " =~ " ${today} " ]]; then
   logger "Today is TOU day. Stopping minner and rebooting $awake"
   if [ $(tmux ls | grep -c "$SESSION") -eq 1 ]; then
       # Solo mining shutdown and reboot 
       echo "TMUX session: $SESSION exists. Stopping miners"

       if tmux has-session -t "$SESSION:$CHIA" 2>/dev/null; then
           echo "Shutting down $CHIA..."
           tmux send-keys -t $SESSION:$CHIA 'chia stop -d all' C-m
           tmux send-keys -t $SESSION:$CHIA 'deactivate' C-m
       fi

       if tmux has-session -t "$SESSION:$TREX" 2>/dev/null; then
           echo "Shutting down $TREX..."
           tmux send-keys -t $SESSION:$TREX send-keys -t 0 C-c
       fi

       if tmux has-session -t "$SESSION:$RAPT" 2>/dev/null; then
           echo "Shutting down $RAPT..."
           tmux send-keys -t $SESSION:$RAPT send-keys -t 0 C-c
       fi

       echo "Closing tmux session $SESSION"
       tmux kill-session -t $SESSION
       sleep 5 && rtcwake -s $sleep -m mem && /home/harvester01/start_mining.sh
   else
       # HiveOS shutdown and reboot
       miner stop && sreboot wakealarm $sleep
   fi
fi
