job "call-home" {
  datacenters = ["dc1"]
  type = "batch"
  periodic {
      cron = "0 */4 * * *"
    }

    task "call-home" {
      driver = "raw_exec"
	  
      config {
      command = "curl"
 	   args = ["-s","https://mattclare.ca/call-home/?label=nomad-cluster"]
		
      }

   }
}