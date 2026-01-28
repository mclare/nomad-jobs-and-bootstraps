/*
For running home assistant on nomad for development
*/

job "home-assistant-dev" {
  datacenters = ["dc1"]
  type        = "service"


  group "home-assistant" {
	
	  network {
	      port "http" { 
			  static = 8123
		  }
	  }
	  
    count = 1
    task "home-assistant-volumes-dev" {
      driver = "docker"
	
    config {
      image = "ghcr.io/home-assistant/home-assistant"
      image_pull_timeout = "10m"
      ports = ["http"]
      volumes  = ["/media/cluster/common/home-assistant-dev/:/config/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements


    }
    resources {
      cpu    = 3000
      memory = 3000
    }

    service {
        name = "homeassistant-dev"
        tags = ["build", "homeassistant", "dev"]
      }

    }
  }
}