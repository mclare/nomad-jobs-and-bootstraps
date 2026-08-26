
job "transmission-openvpn" {
  datacenters = ["dc1"]
  type        = "service"

constraint {
  attribute = "${attr.unique.hostname}"
  value     = "pi4B-02"
}
  group "transmission-openvpn" {
	
    task "rename-torrents" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        image   = "bash:alpine"
        volumes = ["/media/cluster/common/transmission/:/data/"]
        command = "bash"
        args    = ["/local/rename-added.sh"]
      }

      template {
        data = <<EOH
#!/bin/bash
cd /data || exit 1

# Loop through all files in the directory with the .added extension
for file in *.added; do
    if [ -e "$file" ]; then
        mv -- "$file" "${file%.added}.torrent"
        echo "Renamed $file to ${file%.added}.torrent"
    fi
done

# Loop through all files with double .torrent extension
for file in *.torrent; do
    if [[ "$file" =~ \.torrent\.torrent$ ]]; then
        new_name=$(echo "$file" | sed 's/\.torrent\.torrent$/.torrent/')
        mv -- "$file" "$new_name"
        echo "Renamed $file to $new_name"
    fi
done
EOH
        destination = "local/rename-added.sh"
        perms       = "755"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }


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
      volumes  = ["/media/cluster/common/transmission/:/data/"]

      }

      devices = [
      {
        host_path      = "/dev/net/tun"
        container_path = "/dev/net/tun"
      }
]
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