#!/bin/bash

# Read environment variables or set defaults
# Recording the camera stream to a file using ffmpeg. Jobs are to be scheduled by the cron(s) daemon.
# The script calculates the number of seconds remaining in the current hour and records the stream for that duration.
# It then adds extra time to the recording to ensure that the recording is not cut off prematurely.
# Sometimes, ffmpeg hangs and does not exit after the recording is complete. In this case, the script will kill the ffmpeg process after a specified duration with the timeout command (linux only).
source="${SOURCE:-rtsp://@192.168.30.112:554/11}"
device="${DEVICE:-genbolt}"
extra_time="${EXTRA_TIME:-200}"
extra_time_hung="${EXTRA_TIME_HUNG:-360}"
dir="${DIR:-/media/srv/videos/cam/}"
codec="${CODEC}" # Setting the codec variable directly from the environment

d=$(date +%Y_%m_%d-%H)
f=$(date +%Y%m%d)

######################
date
echo "Start recording of $device camera stream $d"
mkdir -p "$dir$f"

# Function to calculate the number of seconds remaining in the current hour
seconds_remaining_in_hour() {
    current_minute=$(date +"%M")
    current_second=$(date +"%S")
    minutes_remaining=$((10#60 - 10#$current_minute - 1))
    minute_seconds_remaining=$((10#60 - 10#$current_second))
    seconds=$((minutes_remaining * 60 - minute_seconds_remaining + extra_time))
    echo "$seconds"
}

# Calculate the number of seconds remaining in the current hour
seconds_until_end_of_hour=$(seconds_remaining_in_hour)

# Calculate the total duration for timeout
timeout_duration=$((seconds_until_end_of_hour + extra_time_hung))

file="$d-$seconds_until_end_of_hour-$device.mp4"
destination_file="$dir$f/$d-$seconds_until_end_of_hour-$device.mp4"

echo "Recording $source to $file for $seconds_until_end_of_hour seconds. Timeout duration: $timeout_duration"

# Run ffmpeg with timeout, with the calculated duration to be recorded to the temporary directory
# timeout --kill-after=5 "$timeout_duration" ffmpeg -fflags +genpts  -rtsp_transport tcp -y -t "$seconds_until_end_of_hour" -i  "$source" -c:v h264_v4l2m2m -c:a aac -r 25 -vf format=yuv420p  "$file"

timeout --kill-after=5 "$timeout_duration" ffmpeg -fflags +genpts  -rtsp_transport tcp -y -t "$seconds_until_end_of_hour" -i  "$source" -c:a aac -r 12 "$file"
date

# Move the file from the temporary directory to the ultimate location
echo "Move the file $file from the temporary directory to $destination_file"

mv -v "$file" "$destination_file"

date
echo "Done"
date
