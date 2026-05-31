/* Woah - this was tricky

Needs the proxy image to exist the docker/VPN into local network 
Also needs a CNAME or other entry in local DNS for transmission in order for transmission-openvpn-proxy to start.

 */

job "transmission-openvpn" {
  datacenters = ["dc1"]
  type        = "service"
  
/*constraint {
  attribute = "${attr.unique.network.ip-address}"
  value     = "192.168.40.12"
}*/
  
constraint {
  attribute = "${attr.unique.hostname}"
  value     = "pi4B-02"
}
  group "transmission-openvpn" {
	
      network {
        port "torrent" {
          static = 9091
        }
        port "torrent-web" {
          static = 8080
        }
      }
	
    task "transmission-openvpn" {
      driver = "docker"
      
      config {
        image = "haugene/transmission-openvpn"
		cap_add = ["NET_ADMIN"]
		ports = ["torrent"]
		interactive = true
		privileged = true
    volumes  = ["/media/cluster/common/transmission/:/data/"]

      }
# Securely pull both Global and Job-Specific variables
# Securely pull ALL variables from the authorized job path
      template {
        data = <<EOH
{{- with nomadVar "nomad/jobs/transmission-openvpn" }}
LOCAL_NETWORK="{{ .local_network }}"
OPENVPN_PROVIDER="{{ .vpn_provider }}"
OPENVPN_USERNAME="{{ .vpn_username }}"
OPENVPN_PASSWORD="{{ .vpn_password }}"
OPENVPN_CONFIG="{{ .vpn_config }}"
{{- end }}
EOH
        destination = "secrets/vpn-config.env"
        env         = true
      }
       resources {
         cpu    = 800
         memory = 800
       }
	 }

   task "transmission-openvpn-proxy" {
      driver = "docker"

      config {
        image       = "haugene/transmission-openvpn-proxy"
        ports       = ["torrent-web"]
        interactive = true
        
        # The Fix: Maps the hardcoded 'transmission' hostname directly to the Nomad Host IP
        extra_hosts = ["transmission:${NOMAD_HOST_IP_torrent}"]
        
        # Security Cleanup: Removed privileged/NET_ADMIN. 
        # The proxy doesn't manage the VPN interface, only the main app container does!
      }
      
      resources {
        cpu    = 200
        memory = 200
      }
    }

  }  
}