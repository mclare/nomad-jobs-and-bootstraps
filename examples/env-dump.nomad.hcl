job "test-variable-access" {
  datacenters = ["dc1"]

  group "test" {
    network {
      port "dns" {
        static = 53
        to     = 53
      }
    }

    task "env-dump" {
      driver = "docker"

      config {
        image = "busybox"
        command = "sh"
        args = ["-c", "env; sleep 300"]
      }

      env {
        VAR_EXAMPLE = "HERE"
        VIRTUAL_HOST = "${NOMAD_HOST_IP_dns}"
      }
    }
  }
}
