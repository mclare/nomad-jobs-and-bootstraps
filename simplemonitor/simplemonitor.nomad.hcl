job "python-simplemonitor" {
  datacenters = ["dc1"]
  type        = "service"

    constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.10"
  }

  group "python-simplemonitor" {
	
    task "python-simplemonitor" {
      driver = "docker"
      
      config {
        image = "python"
        privileged = true
        interactive = true

        volumes  = ["/media/cluster/common/home-assistant/www/monitor:/www/","/media/cluster/config/simplemonitor:/config/"] #Nomad client must have docker.volumes.enabled = true https://developer.hashicorp.com/nomad/docs/drivers/docker#client-requirements

        command = "sh"
        args = ["-c", "/config/bootstrap.sh;"]
      }

      resources {
        cpu    = 900
	      memory = 256
      }

    }
  }
}
