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
        TZ          = "America/Toronto"
        PRIMARY     = "http://192.168.10.55/|password"
        REPLICAS    = "http://192.168.40.12:8053/|password"
        CRON        = "5 */4 * * *"
        RUN_GRAVITY = false 
        
        # Disable full sync to unblock granular control
        FULL_SYNC   = false
        
        # Explicitly enable component syncs
        SYNC_CONFIG_DNS         = true
        # Tell Nebula Sync to skip the properties locked by the replica's env block
        SYNC_CONFIG_DNS_EXCLUDE = "upstreams,listeningMode,dnssec,dhcpIPv6"
        
        # Sync your gravity items (Adlists, domains, groups)
        SYNC_GRAVITY_AD_LIST    = true
        SYNC_GRAVITY_GROUP      = true
        SYNC_CNAME              = true
      }
      
      config {
		  image = "ghcr.io/lovelaze/nebula-sync:latest"
      }

    }
  }
}