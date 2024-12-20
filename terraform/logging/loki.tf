# logging/loki.tf

data "template_file" "loki" {
  template = file("${path.module}/templates/loki-config.tpl")
  vars = {
    retention_period = var.retention_period
  }
}

resource "local_file" "loki_config_generated" {
  # We schrijven de gegenereerde config rechtstreeks in de logging-config directory.
  filename = "${var.infrastructure_base_path}/logging-config/loki-config.yaml"
  content  = data.template_file.loki.rendered
}

resource "docker_container" "loki" {
  name  = "loki"
  image = "grafana/loki:latest"

  user = "10001:10001"  # UID:GID voor Loki

  volumes {
    host_path      = local_file.loki_config_generated.filename
    container_path = "/etc/loki/config.yaml"
    read_only      = true
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/loki-data"
    container_path = "/loki"
  }

  ports {
    internal = 3100
    external = 3100
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.loki.rule"
    value = "Host(`loki.example.com`)"
  }

  labels {
    label = "traefik.http.routers.loki.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.loki.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.services.loki.loadbalancer.server.port"
    value = "3100"
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  networks_advanced {
    name = var.logging_network
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }

  command = [
    "--config.file=/etc/loki/config.yaml",
    "--config.expand-env=true"] 

  depends_on = [
    local_file.loki_config_generated
  ]
}

