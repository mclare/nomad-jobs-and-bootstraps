/*
Created Friday April 18, 2025
https://github.com/lovelaze/nebula-sync
*/

job "pihole-nebula-sync" {
  datacenters = ["dc1"]
  type = "service"

  group "pihole-Group" {
	
    task "nebula-sync" {
      driver = "docker"

	  env {
	    TZ = "America/Toronto"
        PRIMARY = "http://192.168.10.5/|password"
        REPLICAS = "http://192.168.40.12:8053/|password"
        FULL_SYNC=true
        CRON = "5 */4 * * *"
        #Bug with nebula-sync, it doesn't work with the gravity updating and the docker version?
      	RUN_GRAVITY=false 
      }
      
      config {
		  image = "ghcr.io/lovelaze/nebula-sync:latest"
      }

    }
  }
}