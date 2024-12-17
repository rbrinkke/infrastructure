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
  host = "unix:///var/run/docker.sock"
}

provider "vault" {
  # Vault-adres en token worden opgehaald uit omgevingsvariabelen
  address = var.vault_address
  token   = var.vault_token
}

# Variabele voor Vault-adres
variable "vault_address" {
  description = "De URL van de Vault server"
  default     = "http://localhost:8600" # Pas dit aan naar je daadwerkelijke Vault-adres
}

# Variabele voor Vault-token (wordt ingesteld via omgevingsvariabele)
variable "vault_token" {
  description = "De authenticatietoken voor Vault"
  default     = null
}

# Haal configuratie op uit Vault
data "vault_kv_secret_v2" "terraform" {
  mount = "secret"
  name  = "terraform"
}

# Base modules
module "monitoring" {
  source = "./monitoring"
  traefik_network        = docker_network.traefik_network.name
  monitoring_network     = docker_network.monitoring_network.name
  grafana_admin_user     = data.vault_kv_secret_v2.terraform.data["grafana_admin_user"]
  grafana_admin_password = data.vault_kv_secret_v2.terraform.data["grafana_admin_password"]
}

module "auth" {
  source = "./auth"
  traefik_network         = docker_network.traefik_network.name
  auth_network            = docker_network.auth_network.name
  postgres_user           = data.vault_kv_secret_v2.terraform.data["postgres_user"]
  postgres_password       = data.vault_kv_secret_v2.terraform.data["postgres_password"]
  keycloak_admin          = data.vault_kv_secret_v2.terraform.data["keycloak_admin"]
  keycloak_admin_password = data.vault_kv_secret_v2.terraform.data["keycloak_admin_password"]
}

# Data stores
module "redis" {
  source             = "./redis"
  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
  redis_password     = data.vault_kv_secret_v2.terraform.data["redis_password"]
}

module "couchdb" {
  source              = "./couchdb"
  monitoring_network  = docker_network.monitoring_network.name
  traefik_network     = docker_network.traefik_network.name
  couchdb_user        = data.vault_kv_secret_v2.terraform.data["couchdb_user"]
  couchdb_password    = data.vault_kv_secret_v2.terraform.data["couchdb_password"]
  couchdb_secret      = data.vault_kv_secret_v2.terraform.data["couchdb_secret"]
}

module "minio" {
  source              = "./minio"
  monitoring_network  = docker_network.monitoring_network.name
  traefik_network     = docker_network.traefik_network.name
  minio_root_user     = data.vault_kv_secret_v2.terraform.data["minio_root_user"]
  minio_root_password = data.vault_kv_secret_v2.terraform.data["minio_root_password"]
}

module "flask" {
  source              = "./flask"
  monitoring_network  = docker_network.monitoring_network.name
  traefik_network     = docker_network.traefik_network.name
  redis_password      = data.vault_kv_secret_v2.terraform.data["redis_password"]
}

# Backup module
module "backup" {
  source              = "./backup"
  monitoring_network  = docker_network.monitoring_network.name
  traefik_network     = docker_network.traefik_network.name

  backup_password     = data.vault_kv_secret_v2.terraform.data["backup_password"]
  s3_backup_bucket    = data.vault_kv_secret_v2.terraform.data["s3_backup_bucket"]
  aws_access_key      = data.vault_kv_secret_v2.terraform.data["aws_access_key"]
  aws_secret_key      = data.vault_kv_secret_v2.terraform.data["aws_secret_key"]

  postgres_user       = data.vault_kv_secret_v2.terraform.data["postgres_user"]
  postgres_password   = data.vault_kv_secret_v2.terraform.data["postgres_password"]

  redis_password      = data.vault_kv_secret_v2.terraform.data["redis_password"]

  minio_root_user     = data.vault_kv_secret_v2.terraform.data["minio_root_user"]
  minio_root_password = data.vault_kv_secret_v2.terraform.data["minio_root_password"]

  couchdb_user        = data.vault_kv_secret_v2.terraform.data["couchdb_user"]
  couchdb_password    = data.vault_kv_secret_v2.terraform.data["couchdb_password"]

  depends_on = [
    module.auth,
    module.redis,
    module.couchdb,
    module.minio
  ]
}

module "security" {
  source             = "./security"
  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
  depends_on = [
    module.monitoring
  ]
}

# Logging module
module "logging" {
  source             = "./logging"
  monitoring_network = docker_network.monitoring_network.name
  traefik_network    = docker_network.traefik_network.name
  logging_network    = docker_network.logging_network.name
  retention_period   = tonumber(data.vault_kv_secret_v2.terraform.data["backup_retention_days"])

  depends_on = [
    module.monitoring
  ]
}


