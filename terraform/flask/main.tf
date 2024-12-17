resource "docker_container" "flask" {
  name  = "flask"
  image = "python:3.9-slim"

  command = [
    "sh", "-c",
    "apt-get update && apt-get install -y curl && pip install flask redis prometheus_client gunicorn && gunicorn --bind 0.0.0.0:5000 app:app"
  ]

  working_dir = "/app"

  env = [
    "FLASK_ENV=production",
    "REDIS_HOST=redis",
    "REDIS_PORT=6379",
    "REDIS_PASSWORD=${var.redis_password}",
    "WORKERS=4"
  ]

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.flask.rule"
    value = "Host(`app.example.com`)"
  }

  labels {
    label = "traefik.http.routers.flask.entrypoints"
    value = "https"
  }

  labels {
    label = "traefik.http.routers.flask.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.services.flask.loadbalancer.server.port"
    value = "5000"
  }

  volumes {
    host_path      = "${var.infrastructure_base_path}/flask-app"
    container_path = "/app"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:5000/health"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "60s"
  }
}
