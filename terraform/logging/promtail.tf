# logging/promtail.tf

data "template_file" "promtail" {
  template = file("${path.module}/templates/promtail-config.tpl")
  # Als je hier variabelen nodig hebt, kun je die net als bij Loki meegeven:
  # vars = {
  #   promtail_variable = var.promtail_variable
  # }
}

resource "local_file" "promtail_config_generated" {
  filename = "${var.infrastructure_base_path}/logging-config/promtail-config.yaml"
  content  = data.template_file.promtail.rendered
}

resource "docker_container" "promtail_service" {
  name  = "promtail"
  image = "grafana/promtail:latest"

  command = ["-config.file=/etc/promtail/config.yaml"]

  user = "root"

  volumes {
    host_path      = local_file.promtail_config_generated.filename
    container_path = "/etc/promtail/config.yaml"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/lib/docker/containers"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = var.logging_network
  }

  networks_advanced {
    name = var.monitoring_network
  }

  networks_advanced {
    name = var.traefik_network
  }

  restart = "unless-stopped"

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9080/ready || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }

  depends_on = [
    docker_container.loki,
    local_file.promtail_config_generated
  ]
}

