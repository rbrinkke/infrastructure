resource "docker_container" "postgres" {
  name  = "postgres"
  image = "postgres:13"
  
  env = [
    "POSTGRES_DB=keycloak",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}"
  ]
  
  volumes {
    host_path      = "${var.infrastructure_base_path}/postgres-data"
    container_path = "/var/lib/postgresql/data"
  }
  
  networks_advanced {
    name = var.auth_network
  }
  
  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.postgres_user} -d keycloak"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }
}
