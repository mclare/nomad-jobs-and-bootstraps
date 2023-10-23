job "pi-temp-monitor" {
  datacenters = ["dc1"]
  type = "batch"
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }
  constraint {
    attribute    = "${meta.pi}"
    set_contains = "true"
  }
  periodic {
      cron = "*/10 * * * *"
    }
  
  spread {
	    attribute = "${attr.dc}"
	  }
  group "monitor" {
    count = 3

    task "pi-temp" {
      driver = "raw_exec"
      config {
        command = "bash"
        args = [
          "-c",
          "read temp < /sys/class/thermal/thermal_zone0/temp; echo \"$(date),$(hostname),$temp\" >> /media/cluster/config/simplemonitor/pi-temp.log"
        ]
      }
      resources {
        cpu    = 100 # 100 MHz
        memory = 64  # 64 MB
      } 
	  
	  
    }
  }
}