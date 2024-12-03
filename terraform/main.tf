terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock" # Pas dit aan indien nodig, bijvoorbeeld voor Windows of een externe Docker-host
}

resource "docker_network" "webnet" {
  name = "webnet"
}

output "webnet_id" {
  value = docker_network.webnet.id
}

