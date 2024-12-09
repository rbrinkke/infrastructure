variable "traefik_network" {
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
}