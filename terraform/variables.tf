variable "docker_host" {
  description = "Docker host address"
  default     = "unix:///var/run/docker.sock"
}

variable "traefik_admin_auth" {
  description = "Basic auth for Traefik dashboard (format: user:hashed_password)"
  sensitive   = true
}

variable "acme_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "robbrinkkemper@gmail.com"
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
variable "postgres_password" {
  description = "PostgreSQL password for Keycloak database"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true

}
variable "redis_password" {
  description = "Redis password for authentication"
  type        = string
  sensitive   = true
} 
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
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

# Voeg toe aan variables.tf:
variable "backup_password" {
  description = "Password for backup encryption"
  type        = string
  sensitive   = true
}

variable "s3_backup_bucket" {
  description = "S3 bucket name for backups"
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key for S3 backup storage"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for S3 backup storage"
  type        = string
  sensitive   = true
}

# Voeg deze variabelen toe aan variables.tf:

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "keycloak"
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "admin"
}

variable "couchdb_user" {
  description = "CouchDB admin username"
  type        = string
  default     = "admin"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}
