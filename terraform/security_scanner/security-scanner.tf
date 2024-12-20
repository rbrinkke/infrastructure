# Container 2: Security Scanner
resource "docker_container" "security_scanner" {
  name     = "security-scanner"
  hostname = "security-scanner"
  image    = "alpine:latest"
  restart  = "unless-stopped"

  # Start script met alle benodigde setup
  command = [
    "/bin/sh", 
    "-c", 
    <<-EOT
    # Install required packages
    apk add --no-cache \
      curl \
      jq \
      dcron \
      wget \
      bind-tools

    # Setup directories
    mkdir -p /scanner/results /scanner/metrics /var/spool/cron/crontabs

    # Make scripts executable
    chmod +x /scanner-scripts/*.sh

    # Setup cron job
    echo "0 3 * * * /scanner-scripts/scan.sh >> /scanner/scan.log 2>&1" > /var/spool/cron/crontabs/root
    chmod 0600 /var/spool/cron/crontabs/root

    # Initialize cron daemon
    /usr/sbin/crond -f -d 8
    EOT
  ]

  # Volume mappings
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/scanner-results"
    container_path = "/scanner/results"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/metrics"
    container_path = "/scanner/metrics"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/metrics"
    container_path = "/metrics"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/security-scans"
    container_path = "/scanner-scripts"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/security-scans"
    container_path = "/scanner/scripts"  # Extra mount voor script toegang
  }

  # Netwerk configuratie
  networks_advanced {
    name = var.monitoring_network
  }
  networks_advanced {
    name = var.traefik_network
  }

  # Afhankelijkheid
  depends_on = [
    docker_container.trivy
  ]

  # Healthcheck voor de cron daemon
  healthcheck {
    test         = ["CMD", "pgrep", "crond"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "30s"
  }
}
