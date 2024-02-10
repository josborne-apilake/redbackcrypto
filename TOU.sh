#!/bin/bash

SESSION='Mining'
TREX='T-Rex'
RAPT='Raptoreum'
CHIA='Chia'
holidays=("2024-02-15" "2024-02-19" "2024-05-27" "2024-06-19" "2024-07-04" "2024-09-02" "2024-10-14" "2024-11-11" "2024-11-28" "2024-12-25")
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
