job "camera-ftp" {
  datacenters = ["dc1"]
  type        = "service"

  # Constrain to your specific device IP
  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.11"
  }

  group "ftp-group" {
    count = 1

    task "ftp-server" {
      driver = "docker"

      config {
        image        = "delfer/alpine-ftp-server"
        network_mode = "host"
        
        # Binding the host directory to the container's FTP directory
        volumes = [
          "/media/srv/videos/cam/activity/:/ftp/genbolt"
        ]
      }

      # Fetch the password from Nomad Variables and inject it
      template {
        data = <<EOF
{{- with nomadVar "nomad/jobs/camera-ftp" -}}
USERS=genbolt|{{ .ftp_pass }}
{{- end -}}
EOF
        destination = "secrets/ftp.env"
        env         = true
      }

      env {
        ADDRESS  = "192.168.40.11"
        MIN_PORT = "21000"
        MAX_PORT = "21010"
      }

      resources {
        cpu    = 100 # MHz
        memory = 64  # MB
      }
    }
  }
}