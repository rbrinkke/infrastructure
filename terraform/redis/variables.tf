variable "infrastructure_base_path" {
  type    = string
  default = "/var/lib/infrastructure"
}
variable "monitoring_network" {
  description = "Name of the monitoring network"
  type        = string
}

variable "traefik_network" {
  description = "Name of the Traefik network"
  type        = string
}

variable "redis_password" {
  description = "Redis password for authentication"
  type        = string
  sensitive   = true
}

variable "max_memory" {
  description = "Maximum memory Redis can use"
  type        = string
  default     = "256mb"
}

variable "eviction_policy" {
  description = "Redis eviction policy"
  type        = string
  default     = "allkeys-lru"
}
