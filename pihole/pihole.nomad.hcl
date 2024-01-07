/*
Created based on the following:
https://github.com/pi-hole/docker-pi-hole#readme

*/

job "pihole" {
  datacenters = ["dc1"]
  type = "system"

  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.12"
  }

  group "pihole-Group" {
	
      network {
		port "dns" {
		  static = 53
		  to = 53
		}
		port "dns-IOT" {
		  static = 53
		  to = 53
		  host_network = "IOT"
		}
		port "dns-kids" {
		  static = 53
		  to = 53
		  host_network = "kids"
		}
		port "http" {
		  static = 8053
		  to = 80
		}
      }
	
    task "pihole-Server" {
      driver = "docker"

	  env {
        WEBPASSWORD = "<password>"

  	    FRIENDLY_NAME = "PiHole-server-Nomad"
	    TZ = "America/Toronto"
		DNSSEC = "true"
		DHCP_IPv6 = "false"
		DNSMASQ_LISTENING = "all"
		PIHOLE_BASE = "/config/pihole/pihole-storage"
		BLOCK_ICLOUD_PR = "false"
		VIRTUAL_HOST = "${NOMAD_IP_client}"
      }
      
      config {
		  image = "pihole/pihole"
	      ports = ["dns","dns-IOT","dns-kids","http"]
		  volumes  = ["/media/cluster/config/pihole/docker/pihole/:/etc/pihole/","/media/cluster/config/pihole/docker/dnsmasq.d/:/etc/dnsmasq.d/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements
		  cap_add = ["net_admin", "setfcap"]
      }

    }
  }
}