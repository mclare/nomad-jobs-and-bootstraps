job "folding-3" {
  datacenters = ["dc1"]
  priority = 1 /* lowest */
 
  group "folding-at-home" {
    network {
      port "http" {
        to = 7396
      }
    }

    volume "vol-folding" {
      type      = "host"
      read_only = false
      source    = "folding"
    }

    task "folding-at-home" {

// Add constraint to ensure total CPU is over 6000
    constraint {
      attribute = "${attr.cpu.totalcompute}"
      operator  = ">"
      value     = "6000"
    }


      driver = "docker"

      volume_mount {
        volume      = "vol-folding"
  	    destination = "/config"
        read_only = false
      }

      config {
        image = "lscr.io/linuxserver/foldingathome"
        ports = ["http"]
      }

      env { /* This image doesn't use these, but good to have around */
		FOLD_USER = "Matt_Clare"
		FOLD_TEAM = "47936"
        FOLD_ANON = "false"
        FOLD_ALLOW_IP = "192.168.10.1/14"
        POWER = "light"
      }
      resources {
        cpu    = 2000
		    memory = 400
      }
    }
  }
}
