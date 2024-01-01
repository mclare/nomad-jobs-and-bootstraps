job "pocket-mine" {
  datacenters = ["dc1"]
  type        = "service"

constraint {
  attribute = "${attr.unique.network.ip-address}"
  value     = "192.168.40.11"
}

  group "pocket-mine" {
	
    network {
      port "pocketmine" {
        static = 19132
        to = 19132
      }
    }
	
    volume "vol-config" {
      type      = "host"
      read_only = true
      source    = "config"
    }
    volume "vol-common" {
      type      = "host"
      read_only = false
      source    = "common"
    }
	
    task "pocket-mine-fedora" {
      driver = "docker"

      volume_mount {
        volume      = "vol-config"
        destination = "/config"
        read_only   = false
        # could be read_only = true
      }
      volume_mount {
        volume      = "vol-common"
        destination = "/common"
        read_only = false
      }
      
      config {
        image = "fedora"
        cap_add = ["net_bind_service"]
        ports = ["pocketmine"]
        interactive = true
        command = "sh"
        /* The script ends running the pocketmine server and then runs a loop to keep the container
         running incase you want to restart the server without the whole container
         */
        args = ["-c", "/config/pocketmine-mp/bootstrap-fedora.sh;while true; do date; sleep 360; done;"]
      }
      resources {
        cpu    = 2500
        memory = 2000
      }

    }

  }
}