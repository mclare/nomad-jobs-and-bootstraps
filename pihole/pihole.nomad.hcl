/*
Created based on the following:
https://github.com/pi-hole/docker-pi-hole#readme

*/

job "pihole" {
  datacenters = ["dc1"]
  type = "service"

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

		# Upstream DNS 2024.07.0 PIHOLE_DNS_ 2025+ is FTLCONF_dns_upstreams
		PIHOLE_DNS_ = "9.9.9.11;149.112.112.11;2620:fe::11;2620:fe::fe:11"
		FTLCONF_dns_upstreams = "9.9.9.11;149.112.112.11;2620:fe::11;2620:fe::fe:11"

		QUERY_LOGGING = "false"
  	    FRIENDLY_NAME = "PiHole-${NOMAD_HOST_IP_dns}"
	    TZ = "America/Toronto"
		DNSSEC = "true"
		DHCP_IPv6 = "false"
		DNSMASQ_LISTENING = "all"
		# Control FTL's query rate-limiting. Rate-limited queries are answered with a REFUSED reply and not further processed by FTL About per-client rate limiting https://docs.pi-hole.net/ftldns/configfile/#rate_limit
		FTLCONF_RATE_LIMIT = "0/0"
		PIHOLE_BASE = "/config/pihole/pihole-storage"
		BLOCK_ICLOUD_PR = "false"
		VIRTUAL_HOST = "${NOMAD_HOST_IP_dns}"
      }
      
      config {
		  image = "pihole/pihole"
	      ports = ["dns","dns-IOT","dns-kids","http"]
		 # Removing for performance and universality reasons. Now relying on OrbitalSync to sync settings from primary  https://github.com/mattwebbio/orbital-sync.  
		 # volumes  = ["/media/cluster/config/pihole/docker/pihole/:/etc/pihole/","/media/cluster/config/pihole/docker/dnsmasq.d/:/etc/dnsmasq.d/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements
		  cap_add = ["net_admin", "setfcap"]
      }
	  resources {
		cpu    = 500
		memory = 500
      }
    }
  }
}