# minio/main.tf
resource "docker_container" "minio" {
  name  = "minio"
  image = "minio/minio:latest"

  command = ["server", "/data", "--console-address", ":9001"]

  env = [
    "MINIO_ROOT_USER=${var.minio_root_user}",
    "MINIO_ROOT_PASSWORD=${var.minio_root_password}"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  # API Endpoint
  labels {
    label = "traefik.http.routers.minio-api.rule"
    value = "Host(`s3.example.com`)"
  }
  labels {
    label = "traefik.http.routers.minio-api.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.minio-api.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.services.minio-api.loadbalancer.server.port"
    value = "9000"
  }

  # Console UI
  labels {
    label = "traefik.http.routers.minio-console.rule"
    value = "Host(`minio.example.com`)"
  }
  labels {
    label = "traefik.http.routers.minio-console.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.minio-console.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.services.minio-console.loadbalancer.server.port"
    value = "9001"
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/minio-data"
    container_path = "/data"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:9000/minio/health/ready"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "30s"
  }
}

# minio/variables.tf
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "admin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}
