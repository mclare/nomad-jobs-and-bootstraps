# Based on https://developer.hashicorp.com/nomad/docs/job-specification/periodic
# and https://github.com/hashicorp/cronexpr#implementation (crons over cron)
#
job "ffmpeg-genbolt" {
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

group "ffmpeg-genbolt-raw" {
  
    reschedule {
      attempts       = 0
    }
	
    restart {
      attempts = 0
      delay    = "30s"
    }
  
    task "ffmpeg-genbolt-stream" {
      driver = "raw_exec"
	    kill_timeout = "5s"
      config {
      command = "/media/cluster/camera/record_camera_with_ffmpeg.sh"
 	     args = [""]
		
      }
      resources {
        cpu    = 3600
        memory = 1400
      }

      env {
        SOURCE = "rtsp://@192.168.30.112:554/11"
        DEVICE = "garage"
        EXTRA_TIME = "60"
        EXTRA_TIME_HUNG = "360"
        CODEC = "mp4"
        DIR = "/media/srv/videos/cam/"
        SNAPSHOT_OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        SNAPSHOT_SLEEP_TIME = "10"
      }
   }
  
}
}