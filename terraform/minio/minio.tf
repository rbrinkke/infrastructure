resource "docker_container" "minio" {
  name    = "minio"
  image   = "minio/minio:latest"
  command = ["server", "/data", "--console-address", ":9001"]
  env = [
    "MINIO_ROOT_USER=${var.minio_root_user}",
    "MINIO_ROOT_PASSWORD=${var.minio_root_password}"
  ]

  ports {
    internal = 9000
    external = 9000
  }
  ports {
    internal = 9001
    external = 9001
  }

  # Labels defined with dynamic blocks instead of a map
  dynamic "labels" {
    for_each = {
      "traefik.enable"                                             = "true"
      "traefik.http.routers.minio-api.rule"                       = "Host(`s3.example.com`)"
      "traefik.http.routers.minio-api.entrypoints"                = "https"
      "traefik.http.routers.minio-api.tls"                        = "true"
      "traefik.http.services.minio-api.loadbalancer.server.port"  = "9000"
      "traefik.http.routers.minio-console.rule"                   = "Host(`minio.example.com`)"
      "traefik.http.routers.minio-console.entrypoints"            = "https"
      "traefik.http.routers.minio-console.tls"                    = "true"
      "traefik.http.services.minio-console.loadbalancer.server.port" = "9001"
    }
    content {
      label = labels.key
      value = labels.value
    }
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
