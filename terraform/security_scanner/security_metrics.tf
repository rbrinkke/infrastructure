# security_metrics.tf

resource "docker_container" "security_metrics" {
  name     = "security-metrics"
  hostname = "security-metrics"
  image    = "prom/node-exporter:latest"
  restart  = "unless-stopped"

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
}
