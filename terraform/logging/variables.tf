variable "monitoring_network" {
  description = "Naam van het monitoring netwerk"
  type        = string
}

variable "traefik_network" {
  description = "Naam van het Traefik netwerk"
  type        = string
}

variable "logging_network" {
  description = "Naam van het logging netwerk"
  type        = string
}

variable "retention_period" {
  description = "Retentieperiode in uren (bijv. 168 voor 7 dagen)"
  type        = number
  default     = 168
}

variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}

