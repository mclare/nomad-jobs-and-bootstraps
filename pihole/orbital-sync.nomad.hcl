/*
Created Sunday January 7, 2024
https://github.com/mattwebbio/orbital-sync

Reliese on persistent storage at /media/cluster/config/pihole/ - Using docker.volumes.enabled = true
*/

job "pihole-orbital-sync" {
  datacenters = ["dc1"]
  type = "service"

  group "pihole-Group" {

    volume "vol-config" {
      type      = "host"
      read_only = false
      source    = "config"
    }
	
    task "orbital-sync" {
      driver = "docker"

	  env {
	    TZ = "America/Toronto"
        PRIMARY_HOST_BASE_URL = "http://192.168.10.5/"
        PRIMARY_HOST_PASSWORD = "<password>"
        SECONDARY_HOST_1_BASE_URL = "http://192.168.40.12:8053/"
        SECONDARY_HOST_1_PASSWORD = "<password>"
        INTERVAL_MINUTES = "30"

      }

      volume_mount {
		   volume      = "vol-config"
		   destination = "/config"
		   read_only   = false
      }
      
      config {
		  image = "mattwebbio/orbital-sync:1"
		  #volumes  = ["/media/cluster/config/pihole/orbital-sync/:/etc/orbital-sync/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements
      }

    }
  }
}