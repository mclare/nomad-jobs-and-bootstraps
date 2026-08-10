# Nomad Job Specification for STACK Prototyping System
# Untested, as goemaxima will not run on ARM64 architecture.

job "stack-prototype" {
  datacenters = ["dc1"]
  type        = "service"

  group "assessment-engine" {
    count = 1

    network {
      port "db" {
        static = 3306
      }
      port "http" {
        static = 8080
      }
      port "maxima" {
        static = 8081
      }
    }

    # Task 1: Database (MariaDB Backend)
    task "mariadb" {
      driver = "docker"

      config {
        image = "bitnami/mariadb"
        ports = ["db"]
        volumes = [
          "/media/cluster/common/stack-prototype/mariadb_data:/bitnami/mariadb"
        ]
      }

      env {
        MARIADB_USER          = "bn_moodle"
        MARIADB_PASSWORD      = "moodle_pass_123"
        MARIADB_DATABASE      = "bitnami_moodle"
        MARIADB_ROOT_PASSWORD = "root_pass_123"
      }

      resources {
        cpu    = 400
        memory = 512
      }
    }

    # Task 2: CAS Math Evaluator (GoeMaxima Engine)
    task "goemaxima" {
      driver = "docker"

      config {
        image = "mathinstitut/goemaxima"
        ports = ["maxima"]
        tmpfs = [
          "/tmp:rw"
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }

    # Task 3: Front-end Interface & Quiz Bank (Moodle Server)
    task "moodle" {
      driver = "docker"

      config {
        image = "bitnami/moodle"
        ports = ["http"]
        volumes = [
          "/media/cluster/common/stack-prototype/moodle_data:/bitnami/moodle",
          "/media/cluster/common/stack-prototype/plugins/stack:/opt/bitnami/moodle/question/type/stack",
          "/media/cluster/common/stack-prototype/plugins/dfexplicitvaildate:/opt/bitnami/moodle/question/behaviour/dfexplicitvaildate",
          "/media/cluster/common/stack-prototype/plugins/dfcbmexplicitvaildate:/opt/bitnami/moodle/question/behaviour/dfcbmexplicitvaildate",
          "/media/cluster/common/stack-prototype/plugins/adaptivemultipart:/opt/bitnami/moodle/question/behaviour/adaptivemultipart",
          "/media/cluster/common/stack-prototype/plugins/importasversion:/opt/bitnami/moodle/question/bank/importasversion"
        ]
      }

      env {
        MOODLE_DATABASE_HOST        = "${NOMAD_IP_db}"
        MOODLE_DATABASE_PORT_NUMBER = "${NOMAD_PORT_db}"
        MOODLE_DATABASE_USER        = "bn_moodle"
        MOODLE_DATABASE_PASSWORD    = "moodle_pass_123"
        MOODLE_DATABASE_NAME        = "bitnami_moodle"
        
        MOODLE_USERNAME             = "admin"
        MOODLE_PASSWORD             = "AdminPass123!"
        MOODLE_EMAIL                = "admin@brockhomelab.local"
        MOODLE_SITE_NAME            = "STACK Prototyping System"
        
        # Replace with your actual local cluster node IP if mapping directly via LAN
        MOODLE_HOST                 = "${NOMAD_IP_http}:8080"
      }

      resources {
        cpu    = 1500
        memory = 2048
      }
    }
  }
}