resource "docker_container" "traefik" {
  name  = "traefik"
  image = "traefik:v2.4"

  env = [
    "TRAEFIK_PROVIDERS_DOCKER=true",
    "TRAEFIK_API_INSECURE=false",
    "TRAEFIK_API_DASHBOARD=true",
    "TRAEFIK_ENTRYPOINTS_HTTP_ADDRESS=:80",
    "TRAEFIK_ENTRYPOINTS_HTTPS_ADDRESS=:443",
    "TRAEFIK_CERTIFICATESRESOLVERS_LE_ACME_EMAIL=${data.vault_kv_secret_v2.terraform.data["acme_email"]}",
    "TRAEFIK_CERTIFICATESRESOLVERS_LE_ACME_STORAGE=/letsencrypt/acme.json",
    "TRAEFIK_CERTIFICATESRESOLVERS_LE_ACME_HTTPCHALLENGE=true",
    "TRAEFIK_CERTIFICATESRESOLVERS_LE_ACME_HTTPCHALLENGE_ENTRYPOINT=http",
    "TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false",
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.api.rule"
    value = "Host(`traefik.example.com`)"
  }

  labels {
    label = "traefik.http.routers.api.service"
    value = "api@internal"
  }

  labels {
    label = "traefik.http.routers.api.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.api.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.api.middlewares"
    value = "auth"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = "/absolute/path/to/letsencrypt"
    container_path = "/letsencrypt"
  }

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  ports {
    internal = 8080
    external = 8081
  }

  networks_advanced {
    name = docker_network.traefik_network.name
  }
}

