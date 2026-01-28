job "sakai-build-env" {
  datacenters = ["dc1"]
  type = "service"

  group "builder" {
    count = 1

    # -----------------------------
    # Task 1: Bootstrap
    # -----------------------------
    task "bootstrap" {
      driver = "docker"

      config {
        image   = "ubuntu:22.04"
        command = "/bin/bash"
        image_pull_timeout = "10m"
        args    = ["-lc", "/workspace/bootstrap.sh"]

        volumes = [
          "/media/cluster/common/sakai-dev/:/workspace/"
        ]
      }

      resources {
        cpu    = 2000
        memory = 4096
      }
    }

    # -----------------------------
    # Task 2: Interactive shell
    # -----------------------------
    task "shell" {
      driver = "docker"

      config {
        image   = "ubuntu:22.04"
        command = "/bin/bash"
        image_pull_timeout = "10m"
        args    = [
          "-lc",
          # Wait until bootstrap marker exists, then source sakai.sh
          "while [ ! -f /workspace/.bootstrap_done ]; do sleep 1; done; source /etc/profile.d/sakai.sh && sleep infinity"
        ]

        volumes = [
          "/media/cluster/common/sakai-dev/:/workspace/"
        ]
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      service {
        name = "sakai-build-env"
        tags = ["build", "java11", "maven38", "tomcat9"]
      }
    }
  }
}
