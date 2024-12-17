variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "couchdb_user" {
  description = "CouchDB admin username"
  type        = string
  default     = "admin"
}

variable "couchdb_password" {
  description = "CouchDB admin password"
  type        = string
  sensitive   = true
}

variable "couchdb_secret" {
  description = "CouchDB cookie secret for cluster communication"
  type        = string
  sensitive   = true
}
variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
