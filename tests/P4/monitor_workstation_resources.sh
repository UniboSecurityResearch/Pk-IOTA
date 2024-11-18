#!/bin/bash

# Check if two PIDs are passed as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <PID1> <PID2>"
  exit 1
fi

PID1=$1
PID2=$2
LOGFILE="process_monitor_2pids.log"

# Arrays to store values for statistics
cpu1_vals=()
mem1_vals=()
cpu2_vals=()
mem2_vals=()
wattage_vals=()

# Function to output mean and max values when the script is stopped
function print_stats {
  echo "Stopping the monitoring and calculating statistics..."

  # Calculate means
  cpu1_mean=$(echo "${cpu1_vals[@]}" | awk '{ sum=0; for (i=1; i<=NF; i++) sum+=$i; print sum/NF }')
  mem1_mean=$(echo "${mem1_vals[@]}" | awk '{ sum=0; for (i=1; i<=NF; i++) sum+=$i; print sum/NF }')
  cpu2_mean=$(echo "${cpu2_vals[@]}" | awk '{ sum=0; for (i=1; i<=NF; i++) sum+=$i; print sum/NF }')
  mem2_mean=$(echo "${mem2_vals[@]}" | awk '{ sum=0; for (i=1; i<=NF; i++) sum+=$i; print sum/NF }')
  wattage_mean=$(echo "${wattage_vals[@]}" | awk '{ sum=0; for (i=1; i<=NF; i++) sum+=$i; print sum/NF }')

  # Find max values
  cpu1_max=$(echo "${cpu1_vals[@]}" | awk '{ max=$1; for (i=2; i<=NF; i++) if ($i>max) max=$i; print max }')
  mem1_max=$(echo "${mem1_vals[@]}" | awk '{ max=$1; for (i=2; i<=NF; i++) if ($i>max) max=$i; print max }')
  cpu2_max=$(echo "${cpu2_vals[@]}" | awk '{ max=$1; for (i=2; i<=NF; i++) if ($i>max) max=$i; print max }')
  mem2_max=$(echo "${mem2_vals[@]}" | awk '{ max=$1; for (i=2; i<=NF; i++) if ($i>max) max=$i; print max }')
  wattage_max=$(echo "${wattage_vals[@]}" | awk '{ max=$1; for (i=2; i<=NF; i++) if ($i>max) max=$i; print max }')

  echo "Statistics for PID1 (CPU): Mean=$cpu1_mean%, Max=$cpu1_max%"
  echo "Statistics for PID1 (Memory): Mean=$mem1_mean MB, Max=$mem1_max MB"
  echo "Statistics for PID2 (CPU): Mean=$cpu2_mean%, Max=$cpu2_max%"
  echo "Statistics for PID2 (Memory): Mean=$mem2_mean MB, Max=$mem2_max MB"
  echo "Statistics for Voltage: Mean=$wattage_mean V, Max=$wattage_max V"

  exit 0
}

# Trap CTRL-C (SIGINT) to print stats
trap print_stats SIGINT

# Check if both processes are running
if ! ps -p $PID1 > /dev/null; then
  echo "Process with PID $PID1 not found."
  exit 1
fi

if ! ps -p $PID2 > /dev/null; then
  echo "Process with PID $PID2 not found."
  exit 1
fi

echo "Monitoring processes $PID1 and $PID2. Logging to $LOGFILE"
echo "Timestamp, PID1 CPU (%), PID1 Memory (MB), PID2 CPU (%), PID2 Memory (MB), Wattage (microW)" > $LOGFILE

while ps -p $PID1 > /dev/null && ps -p $PID2 > /dev/null; do
  # Timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # CPU usage and Memory usage for PID1
  cpu1=$(ps -p $PID1 -o %cpu --no-headers)
  mem1=$(ps -p $PID1 -o rss --no-headers)
  mem1_mb=$(echo "scale=2; $mem1/1024" | bc)

  # CPU usage and Memory usage for PID2
  cpu2=$(ps -p $PID2 -o %cpu --no-headers)
  mem2=$(ps -p $PID2 -o rss --no-headers)
  mem2_mb=$(echo "scale=2; $mem2/1024" | bc)

  # Measure voltage
  voltage=$(cat /sys/class/power_supply/BAT0/power_now)

  # Log the data
  echo "$timestamp, $cpu1, $mem1_mb, $cpu2, $mem2_mb, $wattage" >> $LOGFILE

  # Store values for statistics
  cpu1_vals+=($cpu1)
  mem1_vals+=($mem1_mb)
  cpu2_vals+=($cpu2)
  mem2_vals+=($mem2_mb)
  voltage_vals+=($wattage)

  # Sleep for 0.5 seconds before repeating
  sleep 0.5
done

echo "One or both processes have terminated."
