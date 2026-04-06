# MyServerConfig

A containerized home server stack running on **Ubuntu**. This repository contains the orchestration and configuration files for a self-hosted CI/CD, monitoring, and password management environment.

## 📂 Repository Structure

This repository contains the exact configuration files used to deploy the server stack:

* `alertmanager/` - Configuration files for Prometheus Alertmanager.
* `prometheus/` - Configuration files and targets for Prometheus monitoring.
* `docker-compose.yml` - The main stack orchestrator for all containerized services.
* `Jenkinsfile` - The Multibranch Pipeline automation script for CI/CD.
* `setup.sh` - Automation script for initial server environment setup.
* `vaultwarden.conf` - Configuration/Proxy settings for the Vaultwarden service.

## 🚀 Services Overview

| Service | Image | Internal Port | External Port |
| :--- | :--- | :--- | :--- |
| **Jenkins** | `jenkins/jenkins:lts` | 8080 | 8080 |
| **Vaultwarden** | `vaultwarden/server:latest` | 80 | 8080 |
| **Prometheus** | `prom/prometheus:latest` | 9090 | 9090 |
| **Alertmanager** | `prom/alertmanager:latest` | 9093 | 9093 |
| **Blackbox Exporter** | `prom/blackbox-exporter:latest` | 9115 | 9115 |
| **WireGuard** | `lscr.io/linuxserver/wireguard:latest` | 51820/udp | 51820/udp |

## 🛠 Prerequisites

### Permission Configuration
Before starting the stack, ensure the correct ownership for the mounted volumes on the Ubuntu host to prevent "Permission Denied" errors in Docker:

```bash
# Jenkins (Default UID 1000)
sudo chown -R 1000:1000 ./jenkins_data

# Prometheus (Default UID 65534)
sudo chown -R 65534:65534 ./prometheus_data
```

## **📦 Deployment**

1. **Clone the repository:**  
```bash
git clone https://github.com/CatCod6r/MyServerConfig.git 
cd MyServerConfig
```

2. **Run the Initialization Script:**  
```bash
chmod +x setup.sh  
./setup.sh
```

3. **Launch the stack:**  
```bash
docker compose up -d
```

## **🤖 CI/CD Integration (Jenkins)**

The included Jenkinsfile is configured for a **Multibranch Pipeline**.

* **Discord Notifications:** Uses withCredentials to securely pull the DISCORD\_WEBHOOK\_URL and send build status alerts.  
* **Automated Triggering:** Handled via GitHub Webhooks pointing to /github-webhook/ or via Multibranch SCM Polling.  
* **Agent Environment:** Uses standard agent any for pipeline execution.

---
