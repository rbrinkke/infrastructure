# security/variables.tf
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "trivy_token" {
  description = "API token for Trivy vulnerability scanner"
  type        = string
  sensitive   = true
  default     = ""  # Maak de token optioneel voor development
}
variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
