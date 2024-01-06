job "www-app" {
  datacenters = ["dc1"]
  type        = "service"
 /* 
  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.13"
  }
*/

  group "www" {
	
	  network {
	      port "http" { 
        to = 80
		  }

	  }

    count = 1
    task "apache" {
      driver = "docker"

	  env {
	    TZ = "America/Toronto"

		VIRTUAL_HOST = "${NOMAD_IP_client}"
      }


    config {
      image = "php:7.2-apache"
      ports = ["http"]
      volumes  = ["/media/cluster/www/:/var/www/html/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements

    }
    resources {
      cpu    = 900
      memory = 300
    }

    }
  }
}