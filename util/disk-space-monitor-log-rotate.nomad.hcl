job "pi-disk-space-temp-monitor-log-rotate" {
  datacenters = ["dc1"]
  type = "batch"
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }
  periodic {
      cron = "1 * * * 1"
    }

  group "monitor" {
    count = 1

    task "log-rotate" {
      driver = "raw_exec"
      config {
        command = "bash"
        args = [
          "-c",
          "gzip /media/cluster/config/simplemonitor/disk-space.log; echo '' > /media/cluster/config/simplemonitor/disk-space.log; gzip /media/cluster/config/simplemonitor/pi-temp.log; echo 'Date,Host,Temp' >  /media/cluster/config/simplemonitor/pi-temp.log;"
        ]
      }
      resources {
        cpu    = 100 # 100 MHz
        memory = 64  # 64 MB
      } 
    }
  }
}
