job "ollama" {
  datacenters = ["dc1"]

      constraint {
        attribute = "${attr.cpu.usablecompute}"
        operator  = ">"
        value     = "8000"
      }

  group "ollama" {
    count = 1  # Adjust for scaling

      volume "ollama-models" {
      type      = "host"
      source    = "ollama-models"
      read_only = false
    }

    network {
      port "http" {
        to = 11434
      }
    }

    task "ollama" {
      driver = "docker"

      #Mixing docker volume mounts and nomad volume mounts to use the nomad volume as a constraint
      volume_mount {
        volume      = "ollama-models"
        destination = "/root/.ollama/models"
      }

      config {
        image = "ollama/ollama:latest" # Example ARM64 build
        ports = ["http"]
        volumes = [
          #"/media/cluster/common/ollama/models:/root/.ollama/models",  # Persist models
          # "local/ollama:/root/.ollama", # Nomad tmpfs
          "/media/cluster/common/ollama/:/config/"
        ]
      }

      resources {
        cpu    = 7400  # 4 vCPUs
        memory = 7400
      }

      service {
        name = "ollama"
        provider = "nomad"
        port = "http"
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
      
env { 
       }

      resources {
        cpu    = 300
	      memory = 300
      }

    }


  }
}
