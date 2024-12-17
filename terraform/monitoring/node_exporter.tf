resource "docker_container" "node_exporter" {
  name  = "node_exporter"
  image = "prom/node-exporter:latest"

  ports {
    internal = 9100
    external = 9100
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.node_exporter.rule"
    value = "Host(`node-exporter.example.com`)"
  }
  labels {
    label = "traefik.http.routers.node_exporter.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.node_exporter.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}