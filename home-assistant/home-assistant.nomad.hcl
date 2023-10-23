/*
https://www.home-assistant.io/
https://www.home-assistant.io/common-tasks/container/
*/

job "home-assistant" {
  datacenters = ["dc1"]
  type        = "service"
  
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "pi4B-01"
  }

  group "home-assistant" {
      volume "vol-cam" {
        type      = "host"
        read_only = false
        source    = "cam"
      } 
      volume "vol-home-assistant" {
        type      = "host"
        read_only = false
        source    = "home-assistant"
      }
	
	  network {
	      port "http" { 
			  static = 8123
		  }
	  }
	  
    count = 1
    task "home-assistant" {
      driver = "docker"

    volume_mount {
      volume      = "vol-home-assistant"
	    destination = "/config"
	    read_only   = false
    }
    volume_mount {
      volume      = "vol-cam"
      destination = "/downloads"
      read_only = false
    }
	
    config {
      image = "ghcr.io/home-assistant/home-assistant:stable"
      ports = ["http"]

    }
    resources {
      cpu    = 2500
      memory = 2500
    }

    }
  }
}