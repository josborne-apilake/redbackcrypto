#!/bin/bash

target_dir="/usr/local/bin/"
target_file="TOU.sh"
hive_crontab="/hive/etc/crontab.root"

week_days=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Staturday")

github_path="https://raw.githubusercontent.com/josborne-apilake/redbackcrypto/main/TOU.sh"

crontab_heading="# HiveOS TOU power cycle"

replace_next_line=false
append_to_file=true

# check that hiveOS crontab file exists
if ! [[ -e "$hive_crontab" ]]; then
   echo "The file '$hive_crontab' does not exist. Are you sure HiveOS is intalled on this machine?"
   exit 1
fi

# Prompt the user for day of week range 0-6
read -p "What is the start day range 0-6, 0 Sunday: " start_range
if ! [[ "$start_range" =~ ^[0-1]?[0-6]$|^6$ ]]; then
    echo "Invalid start day. Please enter a valid number between 0 and 6."
    exit 1
fi
read -p "What is the end day range 0-6, 0 Sunday: " end_range
if ! [[ "$end_range" =~ ^[0-1]?[0-6]$|^6$ ]]; then
    echo "Invalid end day. Please enter a valid number between 0 and 6."
    exit 1
fi

# Prompt the user for the hour of the day to shut down the mining rig
read -p "What hour of the day to shut down mining rig ${week_days[$start_range]}-${week_days[$end_range]} (0-23): " shutdown_hour
if ! [[ "$shutdown_hour" =~ ^[0-2]?[0-9]$|^23$ ]]; then
    echo "Invalid hour. Please enter a valid hour between 0 and 23."
    exit 1
fi

# Prompt the user for the number of seconds to sleep during shutdown
read -p "Enter the number of seconds to sleep: " sleep_seconds
if ! [[ "$sleep_seconds" =~ ^[0-9]+$ ]]; then
    echo "Invalid seconds '$sleep_seconds'. Please enter a valid entry."
    exit 1
fi

# Change directory to /usr/local/bin
if ! [[ -d "$target_dir" ]]; then
   echo "The directory '$target_dir' does not exist."
   exit 1
fi

# Download the TOU shell script from GitHub
cd $target_dir
echo "File: $target_file RAW: $github_path"
curl -O $github_path

# Check if the download was successful
if [ $? -eq 0 ]; then
    # Change file permissions on TOU shell script to executable
    chmod +x "$target_file"
    echo "File $target_file has been downloaded and permissions changed to executable."

    # Construct the cron job entry based on user input
    crontab_entry="* $shutdown_hour * * $start_range-$end_range $target_dir$target_file"

    # Create a temporary file
    tmp_file=$(mktemp "${TMPDIR:-/tmp}/tempfile.XXXXXXXXXX")

    # Read the input file line by line
    while IFS= read -r line; do
        # Check if the line contains the search string
        if [[ $line == *"$crontab_heading"* ]]; then
            # Set the flag to replace the next line
            replace_next_line=true
            echo "$line" >> "$tmp_file"
        elif [ "$replace_next_line" = true ]; then
            # Replace the next line with your desired content
            echo "$crontab_entry" >> "$tmp_file"
            # Reset the flags
            replace_next_line=false
            append_to_file=false
       else
            # Output the current line as is
            echo "$line" >> "$tmp_file"
       fi
    done < "$hive_crontab"

    # Add the comment to /hive/etc/crontab.root if exiting entry not found
    if [ "$append_to_file" = true ]; then
        echo "" >> "$hive_crontab"
        echo "$crontab_heading" >> "$hive_crontab"
        echo "$crontab_entry" >> "$hive_crontab"
        echo "" >> "$hive_crontab"
        echo "Cron job appended to $hive_crontab."
        rm "$tmp_file"
    else
        # Replace the original file with the modified content
        mv "$tmp_file" "$hive_crontab"
        echo "Existing entry in crontab $hive_crontab replaced."
    fi
else
    echo "Error downloading the file from GitHub."
fi
