/*
For running home assistant on nomad for development
*/

job "home-assistant-dev" {
  datacenters = ["dc1"]
  type        = "service"

  group "home-assistant" {
    count = 1

    # Enables access to the shared global/config timezone
    identity {
      env      = true
      file     = true
      roles    = []
      policies = ["shared-vars"]
    }

    network {
      port "http" { 
        static = 8123
      }
    }
    
    task "home-assistant-volumes-dev" {
      driver = "docker"
      shutdown_delay = "15s"

      config {
        image              = "ghcr.io/home-assistant/home-assistant:dev"
        image_pull_timeout = "10m"
        ports              = ["http"]
        volumes            = ["/media/cluster/common/home-assistant-dev/:/config/"]
      }

      # Inject global timezone into container environment
      template {
        data = <<EOH
{{- with nomadVar "global/config" }}
TZ="{{ .timezone }}"
{{- end }}
EOH
        destination = "secrets/ha-dev.env"
        env         = true
      }

      resources {
        cpu    = 3000
        memory = 3000
      }

      service {
        name           = "homeassistant-dev"
        tags           = ["build", "homeassistant", "dev"]
        port           = "http"
        shutdown_delay = "5s" # Fixes the warning by giving routers time to deregister
      }
    }
  }
}