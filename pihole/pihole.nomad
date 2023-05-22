/*
Created Saturday June 18, 2022
https://github.com/pi-hole/docker-pi-hole#readme

Reliese on persistent storage at /media/cluster/config/pihole/ - Using docker.volumes.enabled = true
This instance serves 4 VLAN networks: LAN, IOT, kids, and the rest of the world from a specific Nomad noade (pi4B-02)
*/

job "pihole" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
	value     = "pi4B-02"
  }

  group "pihole-Group" {
	
      network {
		port "dns" {
		  static = 53
		}
		port "dns-LAN" {
		  static = 53
		  host_network = "LAN"
		}
		port "dns-IOT" {
		  static = 53
		  host_network = "IOT"
		}
		port "dns-kids" {
		  static = 53
		  host_network = "kids"
		}
		
		port "http" {
		  to = 80
		}
		port "http-2" {
		  to = 80
		  host_network = "LAN"
		}
      }

    volume "vol-config" {
      type      = "host"
      read_only = false
      source    = "config"
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

      volume_mount {
		   volume      = "vol-config"
		   destination = "/config"
		   read_only   = false
      }
      
      config {
		  image = "pihole/pihole"
	      ports = ["dns","dns-LAN","dns-IOT","dns-kids","http","http-2"]
		  volumes  = ["/media/cluster/config/pihole/docker/pihole/:/etc/pihole/","/media/cluster/config/pihole/docker/dnsmasq.d/:/etc/dnsmasq.d/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements
		  cap_add = ["net_admin", "setfcap"]
      }

    }
  }
}