resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "prom/prometheus:latest"

  volumes {
    host_path      = "${abspath(path.module)}/config/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  ports {
    internal = 9090
    external = 9090
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.prometheus.rule"
    value = "Host(`prometheus.example.com`)"
  }
  labels {
    label = "traefik.http.routers.prometheus.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.prometheus.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}
