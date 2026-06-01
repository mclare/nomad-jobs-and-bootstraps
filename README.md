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

### How to Inject Variables
Before deploying a job from this repository, you must populate the required secrets in your Nomad cluster's state database using the CLI or Web UI.

**CLI Syntax Example:**

nomad var put nomad/jobs/<job-name> <variable_key>="your_secure_password"

### Variables

Below is the active manifest of paths and keys that must be populated in the Nomad state engine for the configurations in this repository to pass validation checks and deploy:

| Job Name / Scope | Nomad Variable Path | Variable Key | Description |
| :--- | :--- | :--- | :--- |
| **`vnc-firefox-alpine`** | `nomad/jobs/vnc-firefox-alpine` | `vnc_user_pass` | The password used to access the TigerVNC server (minimum 6 characters) and the internal `nomaduser` Linux account. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `local_network` | The primary subnet map for the home lab (e.g., `192.168.0.0/18`). Used to punch routing holes through the VPN wrapper. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_provider` | The OpenVPN provider profile selector (e.g., `purevpn`, `nordvpn`). |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_username` | The service account username issued by your VPN provider. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_password` | The service account password issued by your VPN provider. |
| **`transmission-openvpn`** | `nomad/jobs/transmission-openvpn` | `vpn_config` | The specific target country/region / protocol file identifier. |
| *(Global Config)* | `global/config` | `timezone` | Shared system timezone used across containers (e.g., `America/Toronto`). Requires workloads to request the `shared-vars` ACL policy to access. |
| **`pihole`** | `nomad/jobs/pihole` | `web_password` | The administrator dashboard login credentials for the Pi-hole instance. *(Also automatically passed down to the local Nebula Sync sidecar task as its replica password).* |
| **`pihole`** | `nomad/jobs/pihole` | `primary_url` | The full HTTP endpoint of the upstream primary Pi-hole instance master control node (e.g., `http://192.168.10.55/`). |
| **`pihole`** | `nomad/jobs/pihole` | `primary_pass` | The web dashboard administrative password matching the remote upstream Pi-hole master node. |
| **`pihole`** | `nomad/jobs/pihole` | `replica_url` | The local fallback target endpoint address running inside this container stack (e.g., `http://192.168.40.12:8053/`). |