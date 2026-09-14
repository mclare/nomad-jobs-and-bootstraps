/*
For freshening the home assistant development environment, this job will rsync the contents of the home-assistant directory to the home-assistant-dev directory.
*/# 
job "ha-dev-sync" {
  datacenters = ["dc1"]
  type        = "batch"

  group "ha-dev-sync-group" {
    count = 1

    task "rsync-ha-dev" {
      driver = "docker"

      config {
        image   = "alpine:latest"
        command = "/bin/sh"
        args = [
          "-c",
          "apk add --no-cache rsync && rsync -rv --delete /source/ /destination/ --exclude=/www/downloads/ --exclude=/custom_components/"
        ]

        # Mount your cluster paths directly into the task container
        volumes = [
          "/media/cluster/common/home-assistant/:/source/",
          "/media/cluster/common/home-assistant-dev/:/destination/"
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}