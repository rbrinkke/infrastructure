# logging/promtail.tf
resource "local_file" "promtail_configuration" {
  filename = "${abspath(path.module)}/config/promtail-config.yaml"
  content  = <<-EOT
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            timestamp: time
      - timestamp:
          source: timestamp
          format: RFC3339Nano
      - labels:
          stream:
      - output:
          source: output
EOT
}

resource "docker_container" "promtail_service" {
  name  = "promtail"
  image = "grafana/promtail:latest"

  command = ["-config.file=/etc/promtail/config.yaml"]

  # Run as root to access logs
  user = "root"

  volumes {
    host_path      = local_file.promtail_configuration.filename
    container_path = "/etc/promtail/config.yaml"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/lib/docker/containers"
    read_only      = true
  }

  # Add Docker socket for container discovery
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = var.logging_network
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9080/ready || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }

  depends_on = [
    docker_container.loki
  ]
}
