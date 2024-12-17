resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = "gcr.io/cadvisor/cadvisor:latest"

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }
  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }
  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }
  volumes {
    host_path      = "/var/lib/docker/"
    container_path = "/var/lib/docker"
    read_only      = true
  }

  ports {
    internal = 8080
    external = 8082  # Veranderd van 8080 naar 8082
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.cadvisor.rule"
    value = "Host(`cadvisor.example.com`)"
  }
  labels {
    label = "traefik.http.routers.cadvisor.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.cadvisor.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}
