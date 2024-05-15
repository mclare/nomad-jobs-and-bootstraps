# More info at https://docs.linuxserver.io/images/docker-daapd/
job "daapd-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "daapd" {	
	  network {
	    port "dappd" { 
			  static = 3689
		  }
      mode = "host"
	  }
	  
    count = 1
    task "daapd" {
      driver = "docker"

      env {
        TZ = "America/Toronto"
      }
	
      config {
        image = "lscr.io/linuxserver/daapd:latest"
        ports = ["dappd"]
        
        volumes  = ["/media/music/:/music/","/media/cluster/config/daapd/:/config/"]
      #  command = "sh"
      #  args = ["-c", "crontab /config/to-load.cron; crond; while true; do date; sleep 360; done;"]
      }
      resources {
        cpu    = 512
        memory = 512
      }

    }
  }
}