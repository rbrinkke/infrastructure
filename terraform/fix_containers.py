#!/usr/bin/env python3
import re
from pathlib import Path

def fix_cadvisor():
    content = '''resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = "gcr.io/cadvisor/cadvisor:latest"

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }
  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }
  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }
  volumes {
    host_path      = "/var/lib/docker/"
    container_path = "/var/lib/docker"
    read_only      = true
  }

  ports {
    internal = 8080
    external = 8080
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.cadvisor.rule"
    value = "Host(`cadvisor.example.com`)"
  }
  labels {
    label = "traefik.http.routers.cadvisor.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.cadvisor.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}'''
    
    with open('monitoring/cadvisor.tf', 'w') as f:
        f.write(content)
    print("Fixed cadvisor.tf")

def fix_node_exporter():
    content = '''resource "docker_container" "node_exporter" {
  name  = "node_exporter"
  image = "prom/node-exporter:latest"

  ports {
    internal = 9100
    external = 9100
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.node_exporter.rule"
    value = "Host(`node-exporter.example.com`)"
  }
  labels {
    label = "traefik.http.routers.node_exporter.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.node_exporter.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}'''
    
    with open('monitoring/node_exporter.tf', 'w') as f:
        f.write(content)
    print("Fixed node_exporter.tf")

def fix_prometheus():
    content = '''resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "prom/prometheus:latest"

  volumes {
    host_path      = "./prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  ports {
    internal = 9090
    external = 9090
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.prometheus.rule"
    value = "Host(`prometheus.example.com`)"
  }
  labels {
    label = "traefik.http.routers.prometheus.entrypoints"
    value = "https"
  }
  labels {
    label = "traefik.http.routers.prometheus.tls"
    value = "true"
  }

  networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {
    name = var.traefik_network
  }
}'''
    
    with open('monitoring/prometheus.tf', 'w') as f:
        f.write(content)
    print("Fixed prometheus.tf")

def main():
    print("Fixing container configurations...")
    fix_cadvisor()
    fix_node_exporter()
    fix_prometheus()
    print("\nDone! Please run 'terraform plan' again.")

if __name__ == "__main__":
    main()
