job "www-app" {
  datacenters = ["dc1"]
  type        = "service"
 /* 
  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.13"
  }
*/

  group "www-unit" {
	
	  network {
	      port "http" { 
        to = 80
		  }

	  }

    count = 1
    task "nginx" {
      driver = "docker"

	  env {
	    TZ = "America/Toronto"

		VIRTUAL_HOST = "${NOMAD_IP_client}"
      }


    config {
      image = "nginx:latest"
      ports = ["http"]
      volumes  = ["/media/cluster/www/:/usr/share/nginx/html/","/media/cluster/config/nginx/dev/:/etc/nginx/conf.d/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements

    }
    resources {
      cpu    = 900
      memory = 300
    }

    }
  }
}