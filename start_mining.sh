#!/bin/bash

SESSION='Mining'
TREX='T-Rex'
RAPT='Raptoreum'
CHIA='Chia'
RVN_PATH='/home/harvester01/miner'
RVN_CMD='RVN-2miners.sh'
RAPT_PATH='/home/harvester01/rapt/cpuminer-gr-1.2.4.1-args-x86_64_linux'
RAPT_CMD='cpuminer.sh'
CHIA_USER='harvester01'
CHIA_PATH='/home/harvester01/chia-blockchain'
CHIA_CMD='activate'
CHIA_HARVESTER='chia start harvester -r'
CHIA_HARVESTER_STOP='chia stop -d all && deactivate'
S3_MOUNT='s3fs awschiaplot /mnt/s3-bucket -o passwd_file=/home/harvester01/.passwd-s3fs'

# Function to check if the tmux session is already. If it is ask user if they want to kill the existing session
check_session () {
        if [ $(tmux ls | grep -c "$SESSION") -eq 1 ];
        then
                echo "TMUX session: $SESSION exists"
                read -p  "Do you want to kill the current TMUX session?[Y/n] " yn
                case $yn in
                        [Yy]* ) tmux kill-session -t $SESSION; return 0;;
                        [Nn]* ) return 1;;
                        * ) echo "Please answer yes or no.";;
                esac
        else
                return 0
        fi
}

# Function to start the Trex service
start_trex() {
  echo "Starting Trex Miner..."
  tmux send-keys -t $SESSION:$TREX 'cd '"$RVN_PATH"'; ./'"$RVN_CMD" C-m
  echo "Trex harvester started..."
}

# Function to stop the Trex service
stop_trex() {
  echo "Stopping Trex Miner..."
  tmux send-keys -t $SESSION:$TREX C-c
  echo "Trex harvester stopped..."
}

start_chia() {
  echo "Starting CHIA Miner..."
  #tmux send-keys -t $SESSION:$CHIA "$S3_MOUNT && "'cd '"$CHIA_PATH && . ./$CHIA_CMD && $CHIA_HARVESTER" C-m
  tmux send-keys -t $SESSION:$CHIA 'cd '"$CHIA_PATH && . ./$CHIA_CMD && $CHIA_HARVESTER" C-m
  echo "Chia harvester started..."
}

stop_chia() {
  echo "Stopping CHIA Miner..."
  tmux send-keys -t $SESSION:$CHIA 'cd '"$CHIA_PATH"'; '"$CHIA_HARVESTER_STOP" C-m
  echo "Chia harvester stopped..."
}

# Function to create the tmux session and start the miners
create_session () {
        echo "Creating new TMUX mining session: $SESSION"
        tmux new-session -s $SESSION -n terminal -d

        echo "Creating TREX tmux window..."
        tmux neww -t $SESSION -n $TREX
        start_trex

        echo "Creating RAPT tmux window..."
        tmux neww -t $SESSION -n $RAPT
        tmux send-keys -t $SESSION:$RAPT 'cd '"$RAPT_PATH"'; ./'"$RAPT_CMD" C-m
        echo "Raptpreum miner started"

        echo "Creating CHIA tmux window..."
        tmux neww -t $SESSION -n $CHIA
        tmux send-keys -t $SESSION:$CHIA 'su -l '"$CHIA_USER"  C-m
        start_chia
}

# Make sure the script is run as sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check the command-line arguments
if [ "$1" == "--help" ]; then
        echo "Usage: start_mining.sh [--trex|--chia] [start|stop]"
        echo "Start/stop miner(s) (start all miners by default)"
elif [ "$1" == "--trex" ]; then
  if [ "$2" == "start" ]; then
    start_trex
  elif [ "$2" == "stop" ]; then
    stop_trex
  else
    echo "Invalid option. Please use 'start' or 'stop'."
  fi
elif [ "$1" == "--chia" ]; then
  if [ "$2" == "start" ]; then
    start_chia
  elif [ "$2" == "stop" ]; then
    stop_chia
  else
    echo "Invalid option. Please use 'start' or 'stop'."
  fi
else
        # Create the tmux session and start the miners
        check_session
        if [ $? -eq 0 ]; then
                create_session
                echo "Miners started... Done"
                echo Run \'sudo tmux attach-session -t $SESSION\' to attach to the tmux session
        fi
fi
