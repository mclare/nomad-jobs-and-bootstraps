job "vnc-firefox-alpine" {

  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.11"
  }

  datacenters = ["dc1"]
  type        = "service"

  group "vnc-server" {
    count = 1

    network {
      port "vnc" {
        static = 5901
      }
    }
task "vnc-server" {
      driver = "docker"

      config {
        image = "alpine:latest"
        volumes = [
          "/media/cluster/common/vnc/firefox-for-ha/:/opt/",
          "/media/cluster/common/vnc/firefox-for-ha/nomaduser/:/home/nomaduser/"
        ]
        command = "/bin/sh"
        args    = ["/opt/vnc-server-bootstrap.sh"]
        ports   = ["vnc"]
      }

      # ONLY non-sensitive variables go here
      env {
        VNC_USER = "nomaduser"
        DISPLAY  = ":1"
      }

      # BOTH passwords get securely injected here
      template {
        data = <<EOH
USER_PASS="{{ with nomadVar "nomad/jobs/vnc-firefox-alpine" }}{{ .vnc_user_pass }}{{ end }}"
VNC_SERVER_PASS="{{ with nomadVar "nomad/jobs/vnc-firefox-alpine" }}{{ .vnc_user_pass }}{{ end }}"
EOH
        destination = "secrets/vnc.env"
        env         = true
      }

      resources {
        cpu    = 2000
        memory = 2000
      }
    }
  }
} 