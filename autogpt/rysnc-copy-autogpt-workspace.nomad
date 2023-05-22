job "rysnc-copy-autogpt-workspace" {
  datacenters = ["dc1"]
  type = "batch"
  periodic {
      cron = "30 */2 * * *"
    }
  
  constraint {
    attribute    = "${meta.cached_binaries}"
    set_contains = "rsync"
  }

    task "rysnc-copy-autogpt-workspace" {
      driver = "raw_exec"
	  
      config {
         command = "/usr/bin/rsync"
         args = ["-ruh", "/media/cluster/common/autogpt/Auto-GPT/autogpt/auto_gpt_workspace/", "/media/cluster/common/autogpt/auto_gpt_workspace-copy/", "--stats"]
      }

      resources {
        cpu    = 200
        memory = 200
      }
   }
}