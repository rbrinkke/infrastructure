variable "auth_network" {
  description = "Name of the authentication network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "keycloak"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "keycloak_admin" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
