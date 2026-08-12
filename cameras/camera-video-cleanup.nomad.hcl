job "camera-video-cleanup" {
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    crons            = ["0 2 * * *"]
    prohibit_overlap = true
  }

  group "cleanup-group" {
    count = 1

    task "video-cleaner" {
      driver = "raw_exec"

      template {
        destination = "local/cleanup.sh"
        perms       = "755"
        data        = <<EOF
#!/bin/bash
set -euo pipefail

SOURCE_DIR="/media/srv/videos/cam"
TO_BE_DELETED_DIR="/media/srv/videos/cam_to_be_deleted"

# Retention thresholds
MOVE_AFTER_DAYS="30"   # Move to staging after 30 days
PURGE_AFTER_DAYS="60"  # Delete from staging after 60 days total (30 days in staging)

# Ensure both directories exist
mkdir -p "$SOURCE_DIR" "$TO_BE_DELETED_DIR"

echo "$(date +'%Y-%m-%d %H:%M:%S') - Starting camera video cleanup process"

# 1. Move old video folders to "to_be_deleted" after MOVE_AFTER_DAYS
echo "Moving folders older than $${MOVE_AFTER_DAYS} days from $SOURCE_DIR to $TO_BE_DELETED_DIR"
find "$SOURCE_DIR" -mindepth 1 \
  \( -name "cam_to_be_deleted" \) -prune -o \
  \( -name "activity" -o -name "@eaDir" \) -o \
  -type d -mtime +$${MOVE_AFTER_DAYS} -prune -exec bash -c '
    for dir; do
      base="$(basename "$dir")"
      dest="$1/$base"
      if [[ -e "$dest" ]]; then
        dest="${dest}_$(date +%s)"
      fi
      mv "$dir" "$dest" && echo "Moved: $dir -> $dest"
    done
' _ "$TO_BE_DELETED_DIR" {} +

# 2. Delete files in "to_be_deleted" directory older than PURGE_AFTER_DAYS
echo "Removing files in $TO_BE_DELETED_DIR older than $${PURGE_AFTER_DAYS} days"
find "$TO_BE_DELETED_DIR" -type f -mtime +$${PURGE_AFTER_DAYS} -print -delete

# 3. Clean up Synology metadata in "to_be_deleted"
echo "Removing Synology metadata in $TO_BE_DELETED_DIR"
find "$TO_BE_DELETED_DIR" -type d -name '@eaDir' -exec rm -rf {} + -print || true
find "$TO_BE_DELETED_DIR" -type f -name 'SYNOINDEX_MEDIA_INFO' -mtime +$${PURGE_AFTER_DAYS} -print -delete || true

# 4. Remove empty directories in "to_be_deleted"
echo "Removing empty directories in $TO_BE_DELETED_DIR"
find "$TO_BE_DELETED_DIR" -mindepth 1 -type d -empty -print -delete

echo "$(date +'%Y-%m-%d %H:%M:%S') - Video cleanup process completed"
EOF
      }

      config {
        command = "/bin/bash"
        args    = ["local/cleanup.sh"]
      }

      resources {
        cpu    = 100 # MHz
        memory = 64  # MB
      }
    }
  }
}