/*
Created Sunday January 7, 2024
But Orbital Sync is no longer supported by the author.
https://github.com/mattwebbio/orbital-sync

Transitioning to Nebula Sync
https://github.com/lovelaze/nebula-sync
*/

job "pihole-orbital-sync" {
  datacenters = ["dc1"]
  type = "service"

  group "pihole-Group" {
	
    task "orbital-sync" {
      driver = "docker"

	  env {
	    TZ = "America/Toronto"
        PRIMARY_HOST_BASE_URL = "http://192.168.10.5/"
        PRIMARY_HOST_PASSWORD = "<password>"
        SECONDARY_HOST_1_BASE_URL = "http://192.168.40.12:8053/"
        SECONDARY_HOST_1_PASSWORD = "<password>"
        INTERVAL_MINUTES = "90"
      }
      
      config {
		  image = "mattwebbio/orbital-sync:1"
      }

    }
  }
}