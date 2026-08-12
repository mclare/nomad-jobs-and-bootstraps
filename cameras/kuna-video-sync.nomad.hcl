job "kuna-video-sync" {
  datacenters = ["dc1"]
  type        = "batch"

  # Schedule to run daily at 1:00 AM
  periodic {
    crons            = ["0 1 * * *"]
    prohibit_overlap = true
  }

  group "sync-group" {
    count = 1

    task "kuna-syncer" {
      driver = "raw_exec"

      template {
        destination = "local/sync.sh"
        perms       = "755"
        data        = <<EOF
#!/bin/bash
set -euo pipefail

SRC_DIR="/media/cluster/common/home-assistant/www/downloads"
DEST_BASE="/media/srv/videos/cam"

# Ensure directories exist
mkdir -p "$SRC_DIR" "$DEST_BASE"

echo "$(date +'%Y-%m-%d %H:%M:%S') - Starting Kuna video sync process"

# 1. Iterate over media files in HA downloads directory
# -mmin +2 ensures we don't copy a file HA is currently writing
find "$SRC_DIR" -type f \( -name "*.mp4" -o -name "*.jpg" \) -mmin +2 | while read -r file; do
  
  # Get the file's modification date formatted as YYYYMMDD
  FOLDER_DATE=$(date -r "$file" +%Y%m%d)
  TARGET_DIR="$DEST_BASE/$FOLDER_DATE"
  
  # Ensure the target YYYYMMDD folder exists
  mkdir -p "$TARGET_DIR"
  
  # Copy file (-u only copies if source is newer or target doesn't exist)
  if cp -u "$file" "$TARGET_DIR/"; then
    echo "Synced: $(basename "$file") -> $TARGET_DIR/"
  else
    echo "Error copying: $file"
  fi

done

# 2. Housekeeping: Remove files in HA downloads folder older than 90 days
echo "Cleaning up Home Assistant downloads older than 90 days..."
find "$SRC_DIR" -type f -mtime +90 -print -delete

echo "$(date +'%Y-%m-%d %H:%M:%S') - Kuna video sync completed"
EOF
      }

      config {
        command = "/bin/bash"
        args    = ["local/sync.sh"]
      }

      resources {
        cpu    = 100 # MHz
        memory = 64  # MB
      }
    }
  }
}