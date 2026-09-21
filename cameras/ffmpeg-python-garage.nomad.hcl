job "ffmpeg-cameras" {
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    crons            = ["@hourly"]
    prohibit_overlap = false
    time_zone        = "America/Toronto"
  }

  constraint {
    attribute    = "${meta.cached_binaries}"
    set_contains = "ffmpeg"
  }

  # --- CAMERA 1: GARAGE ---
  group "ffmpeg-garage-group" {
    reschedule { attempts = 0 }
    restart    { attempts = 0, delay = "30s" }

    task "ffmpeg-garage-stream" {
      driver       = "raw_exec"
      kill_timeout = "30s"

      config {
        command = "python3"
        args    = ["/media/cluster/camera/record_camera_with_ffmpeg.py"]
      }

      resources {
        cpu    = 3000
        memory = 1200
      }

      env {
        SOURCE                 = "rtsp://@192.168.30.112:554/11"
        DEVICE                 = "garage"
        EXTRA_TIME             = "60"
        EXTRA_TIME_HUNG        = "360"
        CODEC                  = "mp4"
        DIR                    = "/media/srv/videos/cam/"
        SEGMENT_DIR            = "/media/cluster/camera/segments"
        SNAPSHOT_OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        SNAPSHOT_SLEEP_TIME    = "10"
      }
    }
  }

  # --- CAMERA 2: DRIVEWAY ---
  group "ffmpeg-driveway-group" {
    reschedule { attempts = 0 }
    restart    { attempts = 0, delay = "30s" }

    task "ffmpeg-driveway-stream" {
      driver       = "raw_exec"
      kill_timeout = "30s"

      config {
        command = "python3"
        args    = ["/media/cluster/camera/record_camera_with_ffmpeg.py"]
      }

      resources {
        cpu    = 3000
        memory = 1200
      }

      env {
        SOURCE                 = "rtsp://admin:admin@192.168.30.157:554/1"
        DEVICE                 = "driveway"
        EXTRA_TIME             = "60"
        EXTRA_TIME_HUNG        = "360"
        CODEC                  = "mp4"
        DIR                    = "/media/srv/videos/cam/"
        SEGMENT_DIR            = "/media/cluster/camera/segments"
        SNAPSHOT_OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        SNAPSHOT_SLEEP_TIME    = "5"
      }
    }
  }
}
