terraform { 
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

# Base modules
module "monitoring" {
  source = "./monitoring"
  traefik_network    = docker_network.traefik_network.name
  monitoring_network = docker_network.monitoring_network.name
  grafana_admin_user = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
}

module "auth" {
  source = "./auth"
  traefik_network          = docker_network.traefik_network.name
  auth_network             = docker_network.auth_network.name
  postgres_password        = var.postgres_password
  keycloak_admin_password  = var.keycloak_admin_password
}

# Data stores
module "redis" {
  source = "./redis"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  redis_password        = var.redis_password
}

module "couchdb" {
  source = "./couchdb"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  couchdb_password      = var.couchdb_password
  couchdb_secret        = var.couchdb_secret
}

module "minio" {
  source = "./minio"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  minio_root_password   = var.minio_root_password
}

module "flask" {
  source = "./flask"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  redis_password        = var.redis_password
}

module "vault" {
  source = "./vault"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
}

# Backup module
module "backup" {
  source = "./backup"

  monitoring_network   = docker_network.monitoring_network.name
  traefik_network      = docker_network.traefik_network.name

  backup_password      = var.backup_password
  s3_backup_bucket     = var.s3_backup_bucket
  aws_access_key       = var.aws_access_key
  aws_secret_key       = var.aws_secret_key

  postgres_user        = var.postgres_user
  postgres_password    = var.postgres_password

  redis_password       = var.redis_password

  minio_root_user      = var.minio_root_user
  minio_root_password  = var.minio_root_password

  couchdb_user         = var.couchdb_user
  couchdb_password     = var.couchdb_password

  depends_on = [
    module.auth,
    module.redis,
    module.couchdb,
    module.minio
  ]
}

module "security" {
  source = "./security"

  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name

  depends_on = [
    module.monitoring
  ]
}

# Logging module
module "logging" {
  source = "./logging"

  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
  logging_network    = docker_network.logging_network.name
  retention_period   = var.backup_retention_days  # Gebruik de variabele

  depends_on = [
    module.monitoring
  ]
}

