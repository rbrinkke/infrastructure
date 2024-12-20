variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "acme_email" {
  description = "Email address for Let's Encrypt registration"
  type        = string
}

variable "traefik_admin_auth" {
  description = "Basic auth credentials in htpasswd format for Traefik dashboard"
  type        = string
}

variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
