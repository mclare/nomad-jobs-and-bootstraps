# Nomad job file for OLLAMA, with a python container for testing and using the OLLAMA API
# Requies a volume named "ollama-models" - which is the real control on which mode it is deployed to
# The volume is mounted to /root/.ollama/models in the OLLAMA container
# The OLLAMA container is exposed on port 11434
# The python container is interactive and mounts the same volume as the OLLAMA container and can access ollama via API
# This requires CNI (Container Network Interface) plugins to be configured to the Nomad client and to be enabled on the Nomad host

job "ollama" {
  datacenters = ["dc1"]
  constraint {
    attribute = "${attr.cpu.usablecompute}"
    operator  = ">"
    value     = "8000"
  }
  
  group "ollama" {
    count = 1

    volume "ollama-models" {
      type      = "host"
      source    = "ollama-models"
      read_only = false
    }

    network {
      mode = "bridge"  # Changed to bridge mode for container networking
      port "ollama_api" {
        to = 11434
      }
    }

    task "ollama" {
      driver = "docker"
      
      volume_mount {
        volume      = "ollama-models"
        destination = "/root/.ollama/models"
      }
      
      config {
        image = "ollama/ollama:latest"
        ports = ["ollama_api"]
        volumes = [
          "/media/cluster/common/ollama/:/config/"
        ]
      }
      
      resources {
        cpu    = 7400
        memory = 7400
      }
      
      service {
        name = "ollama"
        provider = "nomad"
        port = "ollama_api"
        
        check {
          type     = "tcp"
          port     = "ollama_api"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    task "python-for-ollama" {
      driver = "docker"
      
      config {
        image = "python"
        interactive = true
        volumes = [
          "/media/cluster/common/ollama/:/config/"
        ]
      }
      
      template {
        data = <<EOH
OLLAMA_HOST="http://{{ env "NOMAD_ADDR_ollama_api" }}"
EOH
        destination = "local/env.txt"
        env = true
      }
      
      resources {
        cpu    = 300
        memory = 300
      }
    }
  }
}