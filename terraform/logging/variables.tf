# logging/variables.tf

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
  description = "Retentieperiode in dagen"
  type        = number
}

variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
