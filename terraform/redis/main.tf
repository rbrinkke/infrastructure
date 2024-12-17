# redis/main.tf
resource "docker_container" "redis" {
  name  = "redis"
  image = "redis:7-alpine"

  command = [
    "redis-server",
    "--requirepass ${var.redis_password}",
    "--maxmemory ${var.max_memory}",
    "--maxmemory-policy ${var.eviction_policy}"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.redis.rule"
    value = "Host(`redis.example.com`)"
  }

  labels {
    label = "traefik.http.routers.redis.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.redis.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.services.redis.loadbalancer.server.port"
    value = "6379"
  }

  healthcheck {
    test         = ["CMD", "redis-cli", "ping"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 3
    start_period = "5s"
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/redis-data"
    container_path = "/data"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}

resource "docker_container" "redis_exporter" {
  name  = "redis_exporter"
  image = "oliver006/redis_exporter:latest"

  env = [
    "REDIS_ADDR=redis://redis:6379",
    "REDIS_PASSWORD=${var.redis_password}"
  ]

  ports {
    internal = 9121
    external = 9121
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.redis-exporter.rule"
    value = "Host(`redis-metrics.example.com`)"
  }

  labels {
    label = "traefik.http.routers.redis-exporter.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.redis-exporter.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  depends_on = [
    docker_container.redis
  ]
}

# redis/variables.tf
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "redis_password" {
  description = "Redis password for authentication"
  type        = string
  sensitive   = true
}

variable "max_memory" {
  description = "Maximum memory Redis can use"
  type        = string
  default     = "256mb"
}

variable "eviction_policy" {
  description = "Redis eviction policy"
  type        = string
  default     = "allkeys-lru"
}
