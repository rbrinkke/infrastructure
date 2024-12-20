# Container 1: Trivy Vulnerability Scanner
resource "docker_container" "trivy" {
  name     = "trivy"
  hostname = "trivy"
  image    = "aquasec/trivy:latest"
  restart  = "unless-stopped"

  command = [
    "server",
    "--listen", "0.0.0.0:8083",
    "--cache-dir", "/trivy-cache",
    "--debug",
    "--skip-db-update"
  ]

  # Volume mappings
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  volumes {
    host_path      = "${var.infrastructure_base_path}/trivy-cache"
    container_path = "/trivy-cache"
  }

  # Netwerk configuratie
  networks_advanced {
    name = var.monitoring_network
  }
  networks_advanced {
    name = var.traefik_network
  }

  # Traefik labels
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

  # Healthcheck
  healthcheck {
    test         = ["CMD", "wget", "-q", "-O", "-", "http://localhost:8083/healthz"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "30s"
  }
}
