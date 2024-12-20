resource "docker_container" "redis" {
  name  = "redis"
  image = "redis:7-alpine"

  command = [
    "redis-server",
    "--requirepass ${var.redis_password}",
    "--maxmemory ${var.max_memory}",
    "--maxmemory-policy ${var.eviction_policy}"
  ]

  # Voeg hier de port mapping toe
  ports {
    internal = 6379
    external = 6379
  }

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

