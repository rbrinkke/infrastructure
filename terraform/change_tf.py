#!/usr/bin/env python3
import os
from pathlib import Path

def update_networks_file():
    content = '''# Network resources
resource "docker_network" "traefik_network" {
  name       = "traefik_network"
  driver     = "overlay"
  attachable = true
}

resource "docker_network" "monitoring_network" {
  name       = "monitoring_network"
  driver     = "overlay"
  attachable = true
}'''
    
    with open('networks.tf', 'w') as f:
        f.write(content)
    print("Updated networks.tf")

def update_monitoring_variables():
    content = '''variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}'''
    
    with open('monitoring/variables.tf', 'w') as f:
        f.write(content)
    print("Updated monitoring/variables.tf")

def update_main_module():
    content = '''module "monitoring" {
  source = "./monitoring"
  traefik_network = docker_network.traefik_network.name
  monitoring_network = docker_network.monitoring_network.name
  grafana_admin_user = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
}'''
    
    # Read existing main.tf
    with open('main.tf', 'r') as f:
        main_content = f.read()
    
    # Replace the module block
    import re
    updated_content = re.sub(
        r'module "monitoring".*?\}',
        content,
        main_content,
        flags=re.DOTALL
    )
    
    with open('main.tf', 'w') as f:
        f.write(updated_content)
    print("Updated main.tf")

def update_monitoring_files():
    files = ['cadvisor.tf', 'grafana.tf', 'node_exporter.tf', 'prometheus.tf']
    
    for file in files:
        path = f'monitoring/{file}'
        if os.path.exists(path):
            with open(path, 'r') as f:
                content = f.read()
            
            # Update network configuration
            if 'networks_advanced {' in content:
                content = content.replace(
                    'networks_advanced {',
                    '''networks_advanced {
    name = var.monitoring_network
  }
  
  networks_advanced {'''
                )
                content = content.replace(
                    'docker_network.traefik_network.name',
                    'var.traefik_network'
                )
            
            with open(path, 'w') as f:
                f.write(content)
            print(f"Updated {path}")

def cleanup_outputs():
    content = '''output "traefik_endpoint" {
  value       = "http://traefik.example.com"
  description = "The Traefik dashboard endpoint"
}

output "prometheus_endpoint" {
  value       = "http://prometheus.example.com"
  description = "The Prometheus endpoint"
}

output "grafana_endpoint" {
  value       = "http://grafana.example.com"
  description = "The Grafana endpoint"
}

output "cadvisor_endpoint" {
  value       = "http://cadvisor.example.com"
  description = "The cAdvisor endpoint"
}'''
    
    with open('outputs.tf', 'w') as f:
        f.write(content)
    print("Updated outputs.tf")

def main():
    print("Simplifying Terraform configuration...")
    update_networks_file()
    update_monitoring_variables()
    update_main_module()
    update_monitoring_files()
    cleanup_outputs()
    print("\nDone! Please review the changes and run 'terraform plan'")

if __name__ == "__main__":
    main()
