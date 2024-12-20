resource "docker_container" "keycloak" {
  name  = "keycloak"
  image = "quay.io/keycloak/keycloak:latest"

  command = [
    "start-dev",
    "--http-enabled=true",
    "--db=postgres",
    "--features=preview"  # Enable preview features voor development
  ]

  env = [
    "KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak",
    "KC_DB_USERNAME=${var.postgres_user}",
    "KC_DB_PASSWORD=${var.postgres_password}",
    "KEYCLOAK_ADMIN=${var.keycloak_admin}",
    "KEYCLOAK_ADMIN_PASSWORD=${var.keycloak_admin_password}"
  ]

  networks_advanced {
    name = var.auth_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  # Basic port mapping
  ports {
    internal = 8080
    external = 8180
  }
}
