# Grafana configuratie
resource "docker_service" "grafana" {
  name = "grafana"

  mode {
    replicated {
      replicas = 1
    }
  }

  task_spec {
    container_spec {
      image = "grafana/grafana:latest"

      env = {
        "GF_SECURITY_ADMIN_USER"     = var.grafana_admin_user
        "GF_SECURITY_ADMIN_PASSWORD" = var.grafana_admin_password
      }

      labels {
        label = "traefik.enable"
        value = "true"
      }
      labels {
        label = "traefik.http.routers.grafana.rule"
        value = "Host(`grafana.example.com`)"
      }
    }

    networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
      name = var.traefik_network
    }
  }

  endpoint_spec {
    ports {
      published_port = 3000
      target_port    = 3000
    }
  }
}
