# Based on https://developer.hashicorp.com/nomad/docs/job-specification/periodic
# and https://github.com/hashicorp/cronexpr#implementation (crons over cron)
#
job "ffmpeg-icsee" {
  datacenters = ["dc1"]
  type = "batch"
  periodic {
      crons = ["@hourly"]
      prohibit_overlap = false
      time_zone = "America/Toronto"
    }

constraint {
  attribute    = "${meta.cached_binaries}"
  set_contains = "ffmpeg"
}

group "ffmpeg-icsee-raw" {
  
    reschedule {
      attempts       = 0
    }
	
    restart {
      attempts = 0
      delay    = "30s"
    }
  
    task "ffmpeg-icsee-stream" {
      driver = "raw_exec"
	  kill_timeout = "5s"
      config {
      command = "/media/cluster/camera/record_camera_with_ffmpeg.sh"
 	     args = [""]
		
      }
      resources {
        cpu    = 5000
        memory = 1600
      }

      env {
        SOURCE = "rtsp://admin:admin@192.168.30.67:554"
        DEVICE = "iscee"
        EXTRA_TIME = "200"
        EXTRA_TIME_HUNG = "360"
        CODEC = "mp4"
        DIR = "/media/srv/videos/cam/"
        SNAPSHOT_OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        SNAPSHOT_SLEEP_TIME = "10"
      }
   }

}
}