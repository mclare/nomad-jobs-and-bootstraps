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
WATCH_DIR="/media/srv/videos/cam/activity"
FPS="15" # Adjust this if playback is too fast or slow

echo "Starting Genbolt H.265 to MP4 remuxer..."

while true; do
  # 1. Look for .265 files inside any path containing /record/
  # 2. -mmin +1 ignores files modified in the last minute (prevents converting incomplete FTP uploads)
  # Because the cameras are writing to an NFS mount, we cannot use inotify (file-system events don't trigger reliably across network shares).
  find "$WATCH_DIR" -type f -name "*.265" -path "*/record/*" -mmin +1 | while read -r FILE; do
    
    # Escaped $${ to prevent Nomad HCL parser from reading this as HCL interpolation
    MP4_FILE="$${FILE%.265}.mp4"
    echo "Processing: $FILE"
    
    # Run ffmpeg
    if ffmpeg -y -f hevc -r "$FPS" -i "$FILE" -c copy "$MP4_FILE" < /dev/null; then
      echo "Success! Removing raw file: $FILE"
      rm "$FILE"
    else
      echo "Error converting: $FILE"
    fi
    
  done
  
  # Wait 60 seconds before sweeping the directories again
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