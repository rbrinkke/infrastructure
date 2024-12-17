# security/main.tf
resource "docker_container" "trivy" {
  name     = "trivy"
  hostname = "trivy"  # Expliciete hostname toevoegen
  image    = "aquasec/trivy:latest"
  restart  = "unless-stopped"

  # Dynamische command opbouw met debug
  command = concat(
    [
      "server",
      "--listen", "0.0.0.0:8080",
      "--cache-dir", "/trivy-cache",
      "--debug"  # Debug logging toevoegen
    ],
    var.trivy_token != "" ? ["--token", var.trivy_token] : []
  )

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/trivy-cache"
    container_path = "/trivy-cache"
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.trivy.rule"
    value = "Host(`security.example.com`)"
  }

  labels {
    label = "traefik.http.routers.trivy.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.trivy.tls"
    value = "true"
  }

  healthcheck {
    test         = ["CMD", "wget", "--spider", "--quiet", "http://localhost:8080/health"]
    interval     = "10s"  # Korter interval
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

# Automatische scanning service
resource "docker_container" "security_scanner" {
  name     = "security-scanner"
  hostname = "security-scanner"  # Expliciete hostname toevoegen
  image    = "alpine:latest"
  restart  = "unless-stopped"

  dns_search = ["traefik_network"]  # DNS search toevoegen

  command = [
    "/bin/sh", "-c",
    <<-EOT
      # Install required tools
      apk update && \
      apk add --no-cache \
        curl \
        jq \
        dcron \
        wget \
        bind-tools  # Voor DNS debugging

      # Create required directories
      mkdir -p /scanner/results /scanner/metrics

      # Test DNS resolving
      echo "Testing DNS resolution for trivy..."
      nslookup trivy || true

      # Create scan script
      cat > /scanner/scan.sh << 'EOF'
      #!/bin/sh

      echo "Starting vulnerability scan at $(date)"

      # Ensure trivy server is available
      echo "Testing connection to Trivy server..."
      until wget --spider -q http://trivy:8080/health; do
        echo "Waiting for Trivy server... ($(date))"
        echo "Current DNS resolution:"
        nslookup trivy || true
        sleep 5
      done

      echo "Trivy server is available"

      # Get list of running containers
      echo "Fetching container list..."
      containers=$(curl --unix-socket /var/run/docker.sock "http://localhost/containers/json" 2>/dev/null)

      if [ -z "$${containers}" ]; then
        echo "Error: Could not get container list"
        exit 1
      fi

      # Initialize metrics file
      echo "Initializing metrics..."
      echo "# HELP security_vulnerabilities_total Total number of vulnerabilities by severity" > /scanner/metrics/vulnerabilities.prom
      echo "# TYPE security_vulnerabilities_total gauge" >> /scanner/metrics/vulnerabilities.prom

      total_high=0
      total_critical=0

      # Scan each container
      echo "$${containers}" | jq -r '.[].Image' | while read -r image; do
        echo "Scanning image: $${image}"

        # Create result directory if it doesn't exist
        mkdir -p "/scanner/results/$(date +%Y%m%d)"

        # Run Trivy scan
        echo "Running Trivy scan for $${image}..."
        scan_result=$(curl -v -s -X POST "http://trivy:8080/scan" \
          -H "Content-Type: application/json" \
          -d "{\"image\":\"$${image}\"}" 2>/scanner/results/$(date +%Y%m%d)/curl_debug.log)

        # Save full scan result
        echo "$${scan_result}" > "/scanner/results/$(date +%Y%m%d)/$${image//\//_}.json"

        # Parse vulnerabilities
        high_vulns=$(echo "$${scan_result}" | jq '[.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities[] | select(.Severity == "HIGH")] | length')
        critical_vulns=$(echo "$${scan_result}" | jq '[.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities[] | select(.Severity == "CRITICAL")] | length')

        total_high=$((total_high + high_vulns))
        total_critical=$((total_critical + critical_vulns))

        if [ "$${high_vulns}" -gt 0 ] || [ "$${critical_vulns}" -gt 0 ]; then
          echo "WARNING: Found $${high_vulns} HIGH and $${critical_vulns} CRITICAL vulnerabilities in $${image}"

          # Export metrics for this image
          echo "security_vulnerabilities_high_total{image=\"$${image}\"} $${high_vulns}" >> /scanner/metrics/vulnerabilities.prom
          echo "security_vulnerabilities_critical_total{image=\"$${image}\"} $${critical_vulns}" >> /scanner/metrics/vulnerabilities.prom
        fi
      done

      # Export total metrics
      echo "security_vulnerabilities_high_total{image=\"total\"} $${total_high}" >> /scanner/metrics/vulnerabilities.prom
      echo "security_vulnerabilities_critical_total{image=\"total\"} $${total_critical}" >> /scanner/metrics/vulnerabilities.prom

      # Copy metrics to node exporter directory
      cp /scanner/metrics/vulnerabilities.prom /metrics/vulnerabilities.prom

      echo "Scan completed at $(date)"
EOF

      chmod +x /scanner/scan.sh

      # Setup daily scan
      mkdir -p /var/spool/cron/crontabs
      echo "0 3 * * * /scanner/scan.sh >> /scanner/scan.log 2>&1" > /var/spool/cron/crontabs/root
      chmod 0644 /var/spool/cron/crontabs/root

      # Initial scan
      echo "Running initial scan..."
      /scanner/scan.sh

      # Start cron
      exec crond -f
    EOT
  ]

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

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network  # Toevoegen aan traefik netwerk
  }

  healthcheck {
    test         = ["CMD", "wget", "--spider", "--quiet", "http://trivy:8080/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "40s"
  }

  depends_on = [
    docker_container.trivy
  ]
}

# Prometheus metrics exporter voor security scans
resource "docker_container" "security_metrics" {
  name  = "security-metrics"
  image = "prom/node-exporter:latest"

  command = [
    "--path.rootfs=/host",
    "--collector.textfile.directory=/metrics"
  ]

  volumes {
    host_path      = "${var.infrastructure_base_path}/metrics"
    container_path = "/metrics"
    read_only      = true
  }

  networks_advanced {
    name = var.monitoring_network
  }

  labels {
    label = "prometheus.io/scrape"
    value = "true"
  }

  depends_on = [
    docker_container.security_scanner
  ]
}
