# https://github.com/linuxserver/docker-swag

job "letsencrypt" {
  datacenters = ["dc1"]
  type        = "service"
  
  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.13"
  }

  group "letsencrypt" {
	
	  network {
	      port "http" { 
			  static = 4480
        to = 80
		  }

	      port "https" { 
			  static = 4443
        to = 443
		  }
	  }

    count = 1
    task "swag" {
      driver = "docker"
	
	  env {
	    TZ = "America/Toronto"
      URL = "homenet.cfd"
      VALIDATION=http
      # SUBDOMAINS=www, #optional
      # CERTPROVIDER= #optional
      # DNSPLUGIN=cloudflare #optional
      # PROPAGATION= #optional
      # EMAIL= "logs@mattclare.ca" #optional
      # ONLY_SUBDOMAINS=false #optional
      # EXTRA_DOMAINS= #optional
      # STAGING=false #optional


		VIRTUAL_HOST = "${NOMAD_IP_client}"
      }


    config {
      image = "https://lscr.io/linuxserver/swag:latest"
      ports = ["http","https"]
      volumes  = ["/media/cluster/config/letsencrypt/:/config/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements

    }
    resources {
      cpu    = 300
      memory = 300
    }

    }
  }
}