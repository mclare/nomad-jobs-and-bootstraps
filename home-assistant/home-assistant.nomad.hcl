/*
https://www.home-assistant.io/
https://www.home-assistant.io/common-tasks/container/
*/

job "home-assistant" {
  datacenters = ["dc1"]
  type        = "service"
  
  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.11"
  }

  group "home-assistant" {
	
	  network {
	      port "http" { 
			  static = 8123
		  }
	  }
	  
    count = 1
    task "home-assistant-volumes" {
      driver = "docker"

	
    config {
      image = "ghcr.io/home-assistant/home-assistant"
      ports = ["http"]
      volumes  = ["/media/cluster/common/home-assistant/:/config/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements


    }
    resources {
      cpu    = 2500
      memory = 3000
    }

    }
  }
}