job "python-simplemonitor" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
	  value     = "clustercontrol"
  }

  group "python-simplemonitor" {
	
    volume "vol-config" {
      type      = "host"
      read_only = false
      source    = "config"
    }
    volume "vol-www" {
      type      = "host"
      read_only = false
      source    = "www"
    }
	
    task "python-simplemonitor" {
      driver = "docker"

      volume_mount {
        volume      = "vol-config"
        destination = "/config"
        read_only   = true
      }
      volume_mount {
        volume      = "vol-www"
        destination = "/www"
        read_only = false
      }
      
      config {
        image = "python"
        privileged = true
        interactive = true
        command = "sh"
        args = ["-c", "/config/simplemonitor/bootstrap.sh;"]
      }

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
        retries  = 3
      }
      resources {
        cpu    = 500
	    memory = 256
      }

    }
  }
}
