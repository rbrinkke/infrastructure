# Network resources
resource "docker_network" "traefik_network" {
  name       = "traefik_network"
  driver     = "overlay"
  attachable = true
}

resource "docker_network" "monitoring_network" {
  name       = "monitoring_network"
  driver     = "overlay"
  attachable = true
}
# In networks.tf, voeg toe aan de bestaande netwerken:
resource "docker_network" "auth_network" {
  name       = "auth_network"
  driver     = "overlay"
  attachable = true
}

# Add to networks.tf:
resource "docker_network" "logging_network" {
  name       = "logging_network"
  driver     = "overlay"
  attachable = true
}
