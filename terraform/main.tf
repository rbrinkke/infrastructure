terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.13.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

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

