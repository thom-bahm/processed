#!/bin/bash

# Threshold for long process in seconds (e.g., 5 seconds for testing)
LONG_PROCESS_THRESHOLD=5

# Function to send notification
send_notification() {
  local message=$1
  if command -v notify-send &> /dev/null; then
    notify-send "$message"
  else
    echo "notify-send not found. Install it to receive notifications."
  fi
}

# Function to send pop-up for very long processes
send_popup() {
  local message=$1
  if command -v zenity &> /dev/null; then
    zenity --info --text="$message" --title="Process Notification"
  else
    echo "zenity not found. Install it to receive pop-up notifications."
  fi
}

# Function to monitor processes
monitor_processes() {
  while true; do
    echo "Checking for finished long-running processes..." >> nohup.out
    
    # Get the list of user processes (excluding system and kernel threads)
    ps -eo pid,etime,cmd --sort=start_time --no-header | grep -E -v '^\s*[0-9]+\s+\[.*\]|^\s*[0-9]+\s+/sbin/init|^\s*[0-9]+\s+/lib/systemd|^\s*[0-9]+\s+/usr/sbin|^\s*[0-9]+\s+/sbin/|^\s*[0-9]+\s+@' | while read -r pid etime cmd; do
      # Convert elapsed time to seconds if etime is not empty
      if [ -n "$etime" ]; then
        elapsed_seconds=$(echo $etime | awk -F: '{
          if (NF==3) { print ($1 * 3600) + ($2 * 60) + $3 }
          else if (NF==2) { print ($1 * 60) + $2 }
          else { print $1 }
        }')
        
        # Check if elapsed time is greater than threshold
        if [ -n "$elapsed_seconds" ] && [ "$elapsed_seconds" -ge "$LONG_PROCESS_THRESHOLD" ]; then
          message="Process \"$cmd\" (PID: $pid) finished after running for $elapsed_seconds seconds."
          echo "Sending popup: $message" >> nohup.out
          send_popup "$message"
        fi
      fi
    done
    
    sleep 1  # Check every second
  done
}

monitor_processes


#./usr/share/processed/process_monitor.bash
