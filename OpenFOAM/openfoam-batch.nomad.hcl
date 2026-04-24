job "openfoam-cluster" {
  datacenters = ["dc1"]
  type        = "batch"

  group "compute-nodes" {
    # Increase this count based on how many Pis you want to involve
    count = 2 

    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

    network {
      # 'host' allows MPI to bypass the Docker bridge and talk directly
      # via the 192.168.x.x IPs of your Pis.
      mode = "host"
    }

    task "openfoam-worker" {
      driver = "docker"

      config {
        image = "opencfd/openfoam-run"
        
        # Mapping your shared NFS directly
        volumes = [
          "/media/cluster/common/openfoam:/data"
        ]

        # Keeps the container alive so we can 'exec' into the MPI ranks
        command = "sleep"
        args    = ["infinity"]
      }

      resources {
        # Allocating 4 cores and 3GB RAM for a Pi 4B
        cpu    = 4000
        memory = 3000
      }
    }
  }
}