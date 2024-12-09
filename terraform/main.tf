terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = var.docker_host
}

provider "vault" {
  # Maakt gebruik van VAULT_ADDR en VAULT_TOKEN uit je omgeving
}

# Haal secrets op uit Vault via KV v2
data "vault_kv_secret_v2" "terraform_secrets" {
  mount = "secret"
  name  = "terraform"
}

# Base modules
module "monitoring" {
  source = "./monitoring"
  traefik_network           = docker_network.traefik_network.name
  monitoring_network        = docker_network.monitoring_network.name
  grafana_admin_user        = data.vault_kv_secret_v2.terraform_secrets.data["grafana_admin_user"]
  grafana_admin_password    = data.vault_kv_secret_v2.terraform_secrets.data["grafana_admin_password"]
}

module "auth" {
  source = "./auth"
  traefik_network          = docker_network.traefik_network.name
  auth_network             = docker_network.auth_network.name
  postgres_password        = data.vault_kv_secret_v2.terraform_secrets.data["postgres_password"]
  keycloak_admin_password  = data.vault_kv_secret_v2.terraform_secrets.data["keycloak_admin_password"]
}

# Data stores
module "redis" {
  source = "./redis"
  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
  redis_password     = data.vault_kv_secret_v2.terraform_secrets.data["redis_password"]
}

module "couchdb" {
  source = "./couchdb"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  couchdb_password      = data.vault_kv_secret_v2.terraform_secrets.data["couchdb_password"]
  couchdb_secret        = data.vault_kv_secret_v2.terraform_secrets.data["couchdb_secret"]
}

module "minio" {
  source = "./minio"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  minio_root_password   = data.vault_kv_secret_v2.terraform_secrets.data["minio_root_password"]
}

module "flask" {
  source = "./flask"
  monitoring_network    = docker_network.monitoring_network.name
  traefik_network       = docker_network.traefik_network.name
  redis_password        = data.vault_kv_secret_v2.terraform_secrets.data["redis_password"]
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

  backup_password      = data.vault_kv_secret_v2.terraform_secrets.data["backup_password"]
  s3_backup_bucket     = data.vault_kv_secret_v2.terraform_secrets.data["s3_backup_bucket"]
  aws_access_key       = data.vault_kv_secret_v2.terraform_secrets.data["aws_access_key"]
  aws_secret_key       = data.vault_kv_secret_v2.terraform_secrets.data["aws_secret_key"]

  postgres_user        = var.postgres_user  # Ongevoelig, via tfvars of default
  postgres_password    = data.vault_kv_secret_v2.terraform_secrets.data["postgres_password"]

  redis_password       = data.vault_kv_secret_v2.terraform_secrets.data["redis_password"]

  minio_root_user      = var.minio_root_user  # Ongevoelig
  minio_root_password  = data.vault_kv_secret_v2.terraform_secrets.data["minio_root_password"]

  couchdb_user         = var.couchdb_user  # Ongevoelig
  couchdb_password     = data.vault_kv_secret_v2.terraform_secrets.data["couchdb_password"]

  depends_on = [
    module.auth,
    module.redis,
    module.couchdb,
    module.minio
  ]
}

module "security" {
  source = "./security"
  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
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
  retention_period   = var.backup_retention_days

  depends_on = [
    module.monitoring
  ]
}

