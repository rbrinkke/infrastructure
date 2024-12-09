resource "local_file" "vault_config" {
  filename = "${abspath(path.module)}/config/vault.hcl"
  content  = <<-EOT
    storage "file" {
      path = "/vault/file"
    }

    listener "tcp" {
      address     = "0.0.0.0:8600"
      tls_disable = 1
    }

    api_addr = "http://0.0.0.0:8600"
    ui       = true

    telemetry {
      prometheus_retention_time = "24h"
      disable_hostname          = true
    }
  EOT
}

resource "docker_container" "vault" {
  name  = "vault"
  image = "hashicorp/vault:1.18.2"

  capabilities {
    add = ["IPC_LOCK"]
  }

  command = [
    "vault", "server", "-config=/vault/config/vault.hcl"
  ]

  env = [
    "VAULT_ADDR=http://0.0.0.0:8600",
    "VAULT_API_ADDR=http://0.0.0.0:8600"
  ]

  volumes {
    host_path      = "${abspath(path.module)}/vault-data"
    container_path = "/vault/file"
  }

  volumes {
    host_path      = local_file.vault_config.filename
    container_path = "/vault/config/vault.hcl"
    read_only      = true
  }

  volumes {
    host_path      = "${abspath(path.module)}/logs"
    container_path = "/vault/logs"
  }

  ports {
    internal = 8600
    external = 8600
  }

  #lifecycle {
  #  prevent_destroy = true
  #  ignore_changes = [image]
  #}

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

