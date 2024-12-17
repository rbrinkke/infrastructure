resource "docker_container" "keycloak" {
  name  = "keycloak"
  image = "quay.io/keycloak/keycloak:latest"
  
  command = [
    "start",
    "--db=postgres",
    "--hostname=https://auth.example.com",      # Nu een volledige URL
    "--hostname-admin=https://auth.example.com", # Volledige URL
    "--proxy-headers=forwarded",
    "--http-enabled=true",
    "--http-port=8080",
    "--https-port=8443"
  ]
  
  env = [
    "KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak",
    "KC_DB_USERNAME=${var.postgres_user}",
    "KC_DB_PASSWORD=${var.postgres_password}",
    "KC_BOOTSTRAP_ADMIN_USERNAME=${var.keycloak_admin}",
    "KC_BOOTSTRAP_ADMIN_PASSWORD=${var.keycloak_admin_password}",
    "KEYCLOAK_ADMIN=${var.keycloak_admin}",
    "KEYCLOAK_ADMIN_PASSWORD=${var.keycloak_admin_password}"
  ]
  
  depends_on = [
    docker_container.postgres
  ]
  
  labels {
    label = "traefik.enable"
    value = "true"
  }
  
  labels {
    label = "traefik.http.routers.keycloak.rule"
    value = "Host(auth.example.com)"
  }
  
  labels {
    label = "traefik.http.routers.keycloak.entrypoints"
    value = "https"
  }
  
  labels {
    label = "traefik.http.routers.keycloak.tls"
    value = "true"
  }
  
  labels {
    label = "traefik.http.services.keycloak.loadbalancer.server.port"
    value = "8080"
  }
  
  networks_advanced {
    name = var.auth_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:8080/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "30s"
  }
}
