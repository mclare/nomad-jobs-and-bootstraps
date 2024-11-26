job "pi-disk-space-monitor" {
  datacenters = ["dc1"]
  type = "batch"
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }
  periodic {
      cron = "0 * * * *"
    }
  
  spread {
	    attribute = "${attr.dc}"
	  }
  group "monitor" {
    count = 3

    task "disk-space" {
      driver = "raw_exec"
      config {
        command = "bash"
        args = [
          "-c",
          "echo -n \"Date: $(date)  Hostname: $(hostname) \" >> /media/cluster/config/simplemonitor/disk-space.log; df -h / | grep -v Filesystem >> /media/cluster/config/simplemonitor/disk-space.log"
        ]
      }
      resources {
        cpu    = 100 # 100 MHz
        memory = 64  # 64 MB
      } 
	  
	  
    }
  }
}