#!/bin/bash

# Basisdirectory instellen (aanpassen indien nodig)
BASE_DIR="./logging"

# Mappen aanmaken
echo "Mappen aanmaken..."
mkdir -p "$BASE_DIR/config"

# Bestanden aanmaken met de opgegeven inhoud

# logging/versions.tf
cat <<EOF > "$BASE_DIR/versions.tf"
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
EOF
echo "Bestand aangemaakt: $BASE_DIR/versions.tf"

# logging/variables.tf
cat <<EOF > "$BASE_DIR/variables.tf"
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "logging_network" {
  description = "Name of the logging network"
  type        = string
}

variable "retention_period" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}
EOF
echo "Bestand aangemaakt: $BASE_DIR/variables.tf"

# logging/loki.tf
cat <<EOF > "$BASE_DIR/loki.tf"
resource "docker_container" "loki" {
  name  = "loki"
  image = "grafana/loki:latest"

  command = ["-config.file=/etc/loki/local-config.yaml"]

  volumes {
    host_path      = "\${abspath(path.module)}/config/loki-config.yaml"
    container_path = "/etc/loki/local-config.yaml"
    read_only      = true
  }

  volumes {
    host_path      = "\${abspath(path.module)}/loki-data"
    container_path = "/loki"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.loki.rule"
    value = "Host(\`loki.example.com\`)"
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

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}
EOF
echo "Bestand aangemaakt: $BASE_DIR/loki.tf"

# logging/promtail.tf
cat <<EOF > "$BASE_DIR/promtail.tf"
resource "docker_container" "promtail" {
  name  = "promtail"
  image = "grafana/promtail:latest"

  command = ["-config.file=/etc/promtail/config.yml"]

  volumes {
    host_path      = "\${abspath(path.module)}/config/promtail-config.yml"
    container_path = "/etc/promtail/config.yml"
    read_only      = true
  }

  volumes {
    host_path      = "/var/log"
    container_path = "/var/log"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/lib/docker/containers"
    read_only      = true
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  networks_advanced {
    name = var.logging_network
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9080/ready || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [
    docker_container.loki
  ]
}
EOF
echo "Bestand aangemaakt: $BASE_DIR/promtail.tf"

# logging/config/loki-config.yaml
cat <<'EOF' > "$BASE_DIR/config/loki-config.yaml"
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-01-01
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /loki/index

  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: ${var.retention_period * 24}h

chunk_store_config:
  max_look_back_period: ${var.retention_period * 24}h

table_manager:
  retention_deletes_enabled: true
  retention_period: ${var.retention_period * 24}h
EOF
echo "Bestand aangemaakt: $BASE_DIR/config/loki-config.yaml"

# logging/config/promtail-config.yml
cat <<'EOF' > "$BASE_DIR/config/promtail-config.yml"
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*log
EOF
echo "Bestand aangemaakt: $BASE_DIR/config/promtail-config.yml"

echo "Alle bestanden en mappen zijn succesvol aangemaakt."

