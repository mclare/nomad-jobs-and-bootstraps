#!/bin/bash
#
# Created by Matt Clare and ChatGPT - Friday April 26, 2024
#
# Read environment variables or set defaults
source="${SOURCE:-rtsp://@192.168.30.112:554/11}"
device="${DEVICE:-genbolt}"

#output_file="/media/cluster/www/home-assistant/garage-recent-snapshot.jpg"
output_file="/media/cluster/common/home-assistant/www/$device-recent-snapshot.jpg"
sleep_time="${SLEEP_TIME:-15}"

snapshots=0

# Function to capture a snapshot from the camera
capture_snapshot() {
    if ffmpeg -nostdin -y -i "$source" -f image2 -vframes 1 "$output_file"; then
        snapshots=$((snapshots + 1))
        echo "Snapshot $snapshots captured: $output_file"
		echo "seconds_until_end_of_hour: $seconds_until_end_of_hour - sleep_time: $sleep_time"
    else
        echo "Failed to capture snapshot $snapshots."
    fi
}

# Function to calculate the number of seconds remaining in the current hour
seconds_remaining_in_hour() {
    current_minute=$(date +"%M")
    current_second=$(date +"%S")
    minutes_remaining=$((10#60 - 10#$current_minute - 1))
    minute_seconds_remaining=$((10#60 - 10#$current_second))
#echo "Seconds remaining in the minute: $minute_seconds_remaining"
    seconds=$(((minutes_remaining * 60) - minute_seconds_remaining ))
    echo $seconds
}

# Calculate the number of seconds remaining in the current hour
seconds_until_end_of_hour=$(seconds_remaining_in_hour)

# Main loop to capture snapshots for the specified interval
while [ "$seconds_until_end_of_hour" -gt $((10#$sleep_time)) ]; do
    capture_snapshot

    #Recalculate the number of seconds remaining in the current hour
    seconds_until_end_of_hour=$(seconds_remaining_in_hour)

    # Sleep
    sleep "$sleep_time"
done
echo "Script completed. Exiting."
