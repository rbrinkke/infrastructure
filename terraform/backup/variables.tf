# backup/variables.tf
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

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

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "postgres_user" {
  description = "PostgreSQL username for backup"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password for backup"
  type        = string
  sensitive   = true
}


# Voeg toe aan backup/variables.tf:

variable "redis_password" {
  description = "Redis password for authentication"
  type        = string
  sensitive   = true
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "admin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
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
variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
