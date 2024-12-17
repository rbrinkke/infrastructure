# logging/loki.tf
resource "local_file" "loki_config" {
  filename = "${abspath(path.module)}/config/loki-config.yaml"
  content  = <<-EOT
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem
  compaction_interval: 10m
EOT
}

resource "docker_container" "loki" {
  name  = "loki"
  image = "grafana/loki:latest"

  command = ["--config.file=/etc/loki/config.yaml"]

  volumes {
    host_path      = local_file.loki_config.filename
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
}
