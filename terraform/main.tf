terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.13.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# Networks
resource "docker_network" "webnet" {
  name   = "webnet"
  driver = "overlay"
}

resource "docker_network" "keycloak_network" {
  name   = "keycloak_network"
  driver = "overlay"
}

resource "docker_network" "monitoring_net" {
  name   = "monitoring_net"
  driver = "overlay"
}

# Traefik Configuration
resource "docker_config" "traefik_config" {
  name = "traefik-config-${replace(timestamp(), ":", "-")}"
  data = base64encode(<<-EOT
    api:
      dashboard: true
      insecure: true
    
    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"
      dashboard:
        address: ":8082"
    
    providers:
      docker:
        endpoint: "unix:///var/run/docker.sock"
        swarmMode: true
        exposedByDefault: false
        network: "webnet"
        
    log:
      level: "DEBUG"
      
    certificatesResolvers:
      letsencrypt:
        acme:
          email: "${var.acme_email}"
          storage: "/letsencrypt/acme.json"
          httpChallenge:
            entryPoint: web
  EOT
  )
}

resource "docker_volume" "traefik_certificates" {
  name = "traefik-certificates"
}

resource "docker_service" "traefik" {
  name = "traefik"

  mode {
    replicated {
      replicas = 1
    }
  }

  task_spec {
    container_spec {
      image = "traefik:v2.10"
      
      configs {
        config_id   = docker_config.traefik_config.id
        config_name = docker_config.traefik_config.name
        file_name   = "/etc/traefik/traefik.yml"
      }

      mounts {
        target    = "/var/run/docker.sock"
        source    = "/var/run/docker.sock"
        type      = "bind"
        read_only = true
      }

      mounts {
        target = "/letsencrypt"
        source = docker_volume.traefik_certificates.name
        type   = "volume"
      }

      labels {
        label = "traefik.enable"
        value = "true"
      }
      labels {
        label = "traefik.http.routers.api.rule"
        value = "PathPrefix(`/api`) || PathPrefix(`/dashboard`)"
      }
      labels {
        label = "traefik.http.routers.api.service"
        value = "api@internal"
      }
      labels {
        label = "traefik.http.routers.api.entrypoints"
        value = "dashboard"
      }
    }

    networks_advanced {
      name = docker_network.webnet.name
    }

    placement {
      constraints = ["node.role == manager"]
    }
  }

  endpoint_spec {
    mode = "vip"
    
    ports {
      name           = "web"
      published_port = 80
      target_port    = 80
      protocol       = "tcp"
      publish_mode   = "ingress"
    }

    ports {
      name           = "websecure"
      published_port = 443
      target_port    = 443
      protocol       = "tcp"
      publish_mode   = "ingress"
    }

    ports {
      name           = "dashboard"
      published_port = 8082
      target_port    = 8080
      protocol       = "tcp"
      publish_mode   = "ingress"
    }
  }
}
