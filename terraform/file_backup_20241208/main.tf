# vault/main.tf
resource "docker_container" "vault" {
  name  = "vault"
  image = "hashicorp/vault:latest"

  capabilities {
    add = ["IPC_LOCK"]
  }

  env = [
    "VAULT_ADDR=http://0.0.0.0:8600",
    "VAULT_API_ADDR=http://0.0.0.0:8600",
    "VAULT_LOCAL_CONFIG={\"storage\": {\"file\": {\"path\": \"/vault/file\"}}, \"listener\": {\"tcp\": {\"address\": \"0.0.0.0:8600\", \"tls_disable\": 1}}, \"ui\": true}"
  ]

  ports {
    internal = 8600
    external = 8600
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.vault.rule"
    value = "Host(`vault.example.com`)"
  }

  labels {
    label = "traefik.http.routers.vault.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.vault.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.services.vault.loadbalancer.server.port"
    value = "8600"
  }

  volumes {
    host_path      = "${abspath(path.module)}/vault-data"
    container_path = "/vault/file"
  }

  volumes {
    host_path      = "${abspath(path.module)}/config"
    container_path = "/vault/config"
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  healthcheck {
    test         = ["CMD", "vault", "status"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}
