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

      env {
        VNC_USER        = "nomaduser"
        USER_PASS       = "clusterpassword123"
        VNC_SERVER_PASS = ""
        DISPLAY         = ":1"
      }

      resources {
        cpu    = 2000
        memory = 2000
      }
    }
  }
}