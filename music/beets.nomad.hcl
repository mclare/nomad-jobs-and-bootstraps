# More info at https://docs.linuxserver.io/images/docker-beets/#supported-architectures
job "beets-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "beets" {	
	  network {
	    port "http" { 
			  to = 8337
		  }
	  }
	  
    count = 1
    task "beets" {
      driver = "docker"

      env {
        TZ = "America/Toronto"
      }
	
      config {
        image = "lscr.io/linuxserver/beets:latest"
        ports = ["http"]
        volumes  = ["/media/music/:/music/","/media/cluster/config/beets/:/config/","/media/cluster/common/beets-ingest/:/download/"]
        command = "sh"
        args = ["-c", "crontab /config/to-load.cron; crond; while true; do date; sleep 360; done;"]
      }
      resources {
        cpu    = 1000
        memory = 1536
      }

    }
  }
}