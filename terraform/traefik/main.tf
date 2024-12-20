resource "local_file" "dynamic_config" {
  content = <<-EOT
http:
  middlewares:
    secure-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customFrameOptionsValue: "SAMEORIGIN"

  routers:
    dashboard-https:
      rule: "Host(`traefik.example.com`)"
      service: "api@internal"
      entryPoints:
        - "websecure"
      middlewares:
        - "secure-headers"
      tls: {}

    dashboard-http:
      rule: "Host(`traefik.example.com`)"
      service: "api@internal"
      entryPoints:
        - "traefik"
EOT
  filename = "${var.infrastructure_base_path}/traefik/config/dynamic.yaml"

  provisioner "local-exec" {
    command = "mkdir -p ${dirname(self.filename)}"
  }
}

resource "docker_container" "traefik" {
  name  = "traefik"
  image = "traefik:v2.4"

  env = [
    "TZ=Europe/Amsterdam",
    # Logging
    "TRAEFIK_LOG_LEVEL=DEBUG",

    # API en dashboard
    "TRAEFIK_API_DASHBOARD=true",
    "TRAEFIK_API_INSECURE=true",

    # Docker provider configuratie
    "TRAEFIK_PROVIDERS_DOCKER=true",
    "TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=false",
    "TRAEFIK_PROVIDERS_DOCKER_SWARMMODE=false",
    "TRAEFIK_PROVIDERS_DOCKER_NETWORK=${var.traefik_network}",

    # File provider configuratie
    "TRAEFIK_PROVIDERS_FILE_FILENAME=/etc/traefik/dynamic.yaml",

    # EntryPoints configuratie
    "TRAEFIK_ENTRYPOINTS_WEB_ADDRESS=:80",
    "TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS=:443",
    "TRAEFIK_ENTRYPOINTS_TRAEFIK_ADDRESS=:8080",

    # Ping route voor healthcheck
    "TRAEFIK_PING=true",
    "TRAEFIK_PING_ENTRYPOINT=traefik"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.services.traefik-dashboard.loadbalancer.server.port"
    value = "8080"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/traefik/config/dynamic.yaml"
    container_path = "/etc/traefik/dynamic.yaml"
    read_only      = true
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
    name = var.traefik_network
  }

  networks_advanced {
    name = var.monitoring_network
  }

  healthcheck {
    test         = ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [
    local_file.dynamic_config
  ]
}

