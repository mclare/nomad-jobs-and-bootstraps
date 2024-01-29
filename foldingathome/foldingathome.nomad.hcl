job "folding-3" {
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
        attribute = "${attr.cpu.totalcompute}"
        operator  = ">"
        value     = "6000"
      }

      driver = "docker"

      env { /* This image doesn't use these, but good to have around */
		    FOLD_USER = "Matt_Clare"
		    FOLD_TEAM = "47936"
        FOLD_ANON = "false"
        FOLD_ALLOW_IP = "192.168.10.1/14"
        POWER = "light"
      }

      config {
        image = "lscr.io/linuxserver/foldingathome"
        ports = ["http"]
        volumes  = ["/media/cluster/common/folding-at-home/:/config/"]
      }

      resources {
        cpu    = 2200
		    memory = 400
      }
    }
  }
}
