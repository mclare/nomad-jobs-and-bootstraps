/* Secondary phole job that runs the Pi-hole server and a Nebula Sync sidecar to keep it in sync with the primary instance. */

job "pihole" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.unique.network.ip-address}"
    value     = "192.168.40.12"
  }

  group "pihole-Group" {

    network {
      port "dns" { 
        static = 53
        to = 53
      }
      port "dns-IOT" {
        static = 53
        to = 53
        host_network = "IOT"
      }
      port "dns-kids" { 
        static = 53
        to = 53
        host_network = "kids"
      }
      port "http" { 
        static = 8053
        to = 80
      }
    }
    
    # ----------------------------------------------------
    # TASK 1: THE PI-HOLE SERVER
    # ----------------------------------------------------
    task "pihole-Server" {
      driver = "docker"

      env {
        PIHOLE_DNS_               = "9.9.9.11;149.112.112.11;2620:fe::11;2620:fe::fe:11"
        FTLCONF_dns_upstreams     = "9.9.9.11;149.112.112.11;9.9.9.9;149.112.112.112;2620:fe::fe;2620:fe::9;9.9.9.11;149.112.112.11;2620:fe::11;2620:fe::fe:11;1.0.0.1;1.1.1.1"
        QUERY_LOGGING             = "false"
        FRIENDLY_NAME             = "PiHole-${NOMAD_HOST_IP_dns}"
        DNSSEC                    = "true"
        DHCP_IPv6                 = "true"
        FTLCONF_dns_listeningMode = "ALL"
        FTLCONF_RATE_LIMIT        = "0/0"
        PIHOLE_BASE               = "/config/pihole/pihole-storage"
        BLOCK_ICLOUD_PR           = "false"
        VIRTUAL_HOST              = "${NOMAD_HOST_IP_dns}"
      }
      
      template {
        data = <<EOH
{{- with nomadVar "global/config" }}
TZ="{{ .timezone }}"
{{- end }}

{{- with nomadVar "nomad/jobs/pihole" }}
WEBPASSWORD="{{ .web_password }}"
FTLCONF_webserver_api_password="{{ .web_password }}"
{{- end }}
EOH
        destination = "secrets/pihole.env"
        env         = true
      }
      
      config {
        image   = "pihole/pihole"
        ports   = ["dns","dns-IOT","dns-kids","http"]
        cap_add = ["net_admin", "setfcap"]
      }

      resources {
        cpu    = 500
        memory = 500
      }
    }

    # ----------------------------------------------------
    # TASK 2: THE NEBULA SYNC SIDECAR
    # ----------------------------------------------------
    task "nebula-sync" {
      driver = "docker"

      env {
        CRON                    = "5 */4 * * *"
        RUN_GRAVITY             = false
        FULL_SYNC               = false
        SYNC_CONFIG_DNS         = true
        SYNC_CONFIG_DNS_EXCLUDE = "upstreams,listeningMode,dnssec"
        SYNC_GRAVITY_AD_LIST    = true
        SYNC_GRAVITY_GROUP      = true
        SYNC_CNAME              = true
      }
      
      # Securely map the primary configs and reuse the Pi-hole's web_password for the replica!
      template {
        data = <<EOH
{{- with nomadVar "global/config" }}
TZ="{{ .timezone }}"
{{- end }}

PRIMARY="{{ with nomadVar "nomad/jobs/pihole" }}{{ .primary_url }}{{ end }}|{{ with nomadVar "nomad/jobs/pihole" }}{{ .primary_pass }}{{ end }}"
REPLICAS="{{ with nomadVar "nomad/jobs/pihole" }}{{ .replica_url }}{{ end }}|{{ with nomadVar "nomad/jobs/pihole" }}{{ .web_password }}{{ end }}"
EOH
        destination = "secrets/sync.env"
        env         = true
      }
      
      config {
        image = "ghcr.io/lovelaze/nebula-sync:latest"
      }
      
      resources {
        cpu    = 200
        memory = 200
      }
    }
  }
}