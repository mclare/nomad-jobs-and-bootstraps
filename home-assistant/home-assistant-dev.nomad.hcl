/*
For running home assistant on nomad for development
*/

job "home-assistant-dev" {
  datacenters = ["dc1"]
  type        = "service"

  group "home-assistant" {
    count = 1

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

      resources {
        cpu    = 3000
        memory = 3000
      }

      service {
        name           = "homeassistant-dev"
        tags           = ["build", "homeassistant", "dev"]
        port           = "http"
      }
    }
  }
}