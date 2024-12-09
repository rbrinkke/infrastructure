# Network resources
resource "docker_network" "traefik_network" {
  name       = data.vault_kv_secret_v2.terraform.data["traefik_network_name"]
  driver     = "overlay"
  attachable = true
}

resource "docker_network" "monitoring_network" {
  name       = data.vault_kv_secret_v2.terraform.data["monitoring_network_name"]
  driver     = "overlay"
  attachable = true
}

# In networks.tf, voeg toe aan de bestaande netwerken:
resource "docker_network" "auth_network" {
  name       = data.vault_kv_secret_v2.terraform.data["auth_network_name"]
  driver     = "overlay"
  attachable = true
}

# Add to networks.tf:
resource "docker_network" "logging_network" {
  name       = data.vault_kv_secret_v2.terraform.data["logging_network_name"]
  driver     = "overlay"
  attachable = true
}
