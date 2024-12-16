job "ffmpeg-snapshots" {
  datacenters = ["dc1"]
  type        = "service"

constraint {
  attribute    = "${meta.cached_binaries}"
  set_contains = "ffmpeg"
}
  group "ffmpeg-snapshot-constant" {
	
    task "ffmpeg-snapshot-constant-genbolt" {
       driver = "raw_exec"
       kill_timeout = "5s"
     config {
       command = "/media/cluster/camera/ffmpeg-constant-snapshot.sh"
	
     }

     resources {
       cpu    = 600
       memory = 512
     }

      env {
        SOURCE = "rtsp://@192.168.30.112:554/11"
        OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        DEVICE = "garage"
        SLEEP_TIME = "10"
      }
	 }

    task "ffmpeg-snapshot-constant-iscee" {
       driver = "raw_exec"
       kill_timeout = "5s"
     config {
       command = "/media/cluster/camera/ffmpeg-constant-snapshot.sh"
     }

     resources {
       cpu    = 600
       memory = 512
     }


      env {

        SOURCE = "rtsp://admin:admin@192.168.30.67:554"
        OUTPUT_FOLDER = "/media/cluster/common/home-assistant/www"
        DEVICE = "iscee"
        SLEEP_TIME = "10"
      }
	 }

  }  
}