# https://hub.docker.com/r/linuxserver/beets

job "beets-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "beets" {
      volume "vol-music" {
        type      = "host"
        read_only = false
        source    = "music"
      }
      volume "vol-config-beets" {
        type      = "host"
        read_only = false
        source    = "config-beets"
      }
      volume "vol-common" {
        type      = "host"
        read_only = false
        source    = "common"
      }
	
	  network {
	    port "http" { 
			  to = 8337
		  }
	  }
	  
    count = 1
    task "beets" {
      driver = "docker"
	  
    volume_mount {
	    volume      = "vol-music"
      destination = "/music"
      read_only   = false
    }
    volume_mount {
      volume      = "vol-config-beets"
	    destination = "/config"
	    read_only   = false
    }
    volume_mount {
      volume      = "vol-common"
	    destination = "/downloads"
      read_only = false
    }
	
    config {
      image = "linuxserver/beets"
      ports = ["http"]
      command = "sh"
      args = ["-c", "crontab /config/to-load.cron; crond; while true; do date; sleep 360; done;"]
    }
    resources {
        cpu    = 400
		    memory = 512
      }

    }
  }
}