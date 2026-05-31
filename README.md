# Raspberry Pi Nomad Cluster: Jobs & Bootstraps

Homelab nomad cluster [Hasicrop nomad](https://github.com/hashicorp/nomad) jobs and associated bootstrap scripts.

This repository contains the Nomad job specifications (`.nomad.hcl`) and accompanying bootstrap shell scripts used to orchestrate services across a lightweight Raspberry Pi home lab cluster. 

The goal of this project is to maintain an infrastructure-as-code approach for all containerized workloads, ensuring that services like Pi-hole, Nebula Sync, and isolated VNC environments are highly available, easily reproducible, and securely configured.

## Architecture Context
- **Hardware:** Raspberry Pi cluster (ARM64 architecture).
- **Orchestration:** HashiCorp Nomad (Service deployments, templating, and scheduling).
- **Service Mesh / Discovery:** HashiCorp Consul (for dynamic network bindings and service registration).

---

## Secrets Management & Nomad Variables

To adhere to security best practices, **no plaintext passwords or sensitive API tokens are stored in these job files.** This repository utilizes Nomad's native [Variables](https://developer.hashicorp.com/nomad/docs/concepts/variables) feature. Sensitive environment variables are injected at runtime using Nomad's `template` stanzas, which securely mount the variables into a hidden, in-memory RAM disk inside the containers.

### Variables
| Job Name | Nomad Variable Path | Variable Key | Description |
| :--- | :--- | :--- | :--- |
| **`vnc-firefox-alpine`** | `nomad/jobs/vnc-firefox-alpine` | `vnc_user_pass` | The password used to access the TigerVNC server (minimum 6 characters) and the internal OS account. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | The primary subnet for the home lab (e.g., `192.168.0.0/18`). Used to punch local routing holes in VPN containers. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_provider` | The OpenVPN provider name (e.g., `purevpn`, `nordvpn`). |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_username` | The service account username for the VPN provider. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_password` | The service account password for the VPN provider. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_config` | The specific OpenVPN configuration target/region to connect to. |