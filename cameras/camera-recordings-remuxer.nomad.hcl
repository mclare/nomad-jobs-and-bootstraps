job "camera-recordings-remuxer" {
  datacenters = ["dc1"]
  type        = "service"

  group "remux-group" {
    count = 1

    task "ffmpeg-watcher" {
      driver = "raw_exec"

      template {
        destination = "local/remux.sh"
        perms       = "755"
        data        = <<EOF
#!/bin/bash

# Configuration
WATCH_DIR="/media/srv/videos/cam"
FPS="15" # Adjust this if playback speed is off

echo "Starting Genbolt H.265 to MP4 remuxer..."

while true; do
  find "$WATCH_DIR" -type f -name "*.265" -path "*/record/*" -mmin +1 | while read -r FILE; do
    
    MP4_FILE="$${FILE%.265}.mp4"
    echo "Processing: $FILE"
    
    # Key parameters for ffmpeg remuxing:
    # 1. -loglevel warning : Suppresses non-fatal NALU 39/40 noise
    # 2. -fflags +genpts   : Generates proper timestamps for raw elementary streams
    # 3. -tag:v hvc1       : FORCES Apple QuickTime / macOS Preview compatibility
    if ffmpeg -loglevel warning -fflags +genpts -y -f hevc -r "$FPS" -i "$FILE" -c copy -tag:v hvc1 "$MP4_FILE" < /dev/null; then
      echo "Success! Removing raw file: $FILE"
      rm "$FILE"
    else
      echo "Error converting: $FILE"
    fi
    
  done
  
  sleep 60
done
EOF
      }

      config {
        command = "/bin/bash"
        args    = ["local/remux.sh"]
      }

      resources {
        cpu    = 200 # MHz
        memory = 128 # MB
      }
    }
  }
}