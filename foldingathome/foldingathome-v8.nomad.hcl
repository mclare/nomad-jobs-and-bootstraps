#About image https://docs.linuxserver.io/images/docker-foldingathome/
job "folding-v8" {
  datacenters = ["dc1"]
  priority = 1 /* lowest */
 
  group "folding-at-home" {
    network {
      port "http" {
        to = 7396
      }
    }

    task "folding-at-home" {

// Add constraint to ensure total CPU is over 6000
      constraint {
        attribute = "${attr.cpu.usablecompute}"
        operator  = ">"
        value     = "8000"
      }


      driver = "docker"

      env {
        FOLD_ALLOW_IP = "192.168.10.1/14"
        ACCOUNT_TOKEN = "wSBj6wSBm8Y0gm8Yx33bTx33EiKriEiLQzyEAQz96a4"
        MACHINE_NAME = "Cluster Folding@Home"

      }

      config {
        image = "lscr.io/linuxserver/foldingathome"
        ports = ["http"]
        volumes  = ["/media/cluster/common/folding-at-home/:/config/"]
      }

      resources {
        cpu    = 4200
		    memory = 400
      }
    }
  }
}
