job "pi-disk-space-monitor" {
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
/*
Credit ChatGPT 

This revised configuration is a periodic job that runs the task every hour (as specified by the interval parameter). The task runs on all clients in the specified datacenter (in this case, "dc1"). The task itself is similar to the previous ones, but it does not include the infinite loop and sleep command, as it is designed to run only once per interval.

You can adjust the interval at which the task runs by modifying the value of the interval parameter. The interval can be specified using a duration string, such as "1h" for one hour or "30m" for 30 minutes. You can also modify the command itself to customize the output or gather different types of information about disk space usage.

I hope this helps! Let me know if you have any questions or need further assistance.

*/