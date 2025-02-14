# More info at https://www.ocr4all.org/guide/setup-guide/quickstart
#
# But as of 2025-02-13, the OCR4all project will not run on ARM64 architecture, so this job will not work on the cluster.
job "ocr4all-service" {
  datacenters = ["dc1"]
  type        = "service"

  group "ocr4all" {	
	  network {
	    port "http" { 
			  to = 1476
		  }
	  }

    update {
        progress_deadline = "20m"  # Ensure this is longer than kill_timeout
    }
	  
    count = 1
    task "ocr4all" {
      driver = "docker"
      config {
        image = "uniwuezpd/ocr4all"
        ports = ["http"]
        volumes  = ["/media/cluster/common/ocr4all/data:/var/ocr4all/data /","/media/cluster/common/ocr4all/models/:/var/ocr4all/models/custom/"]
      }
      resources {
        cpu    = 3000
        memory = 1536
      }

       kill_timeout = "15m"  # Allow the task to run longer before being killed, this one's big so pulling it from dockerhub takes a while

    }
  }
}