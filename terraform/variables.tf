# Definieer hier variabelen die je nodig hebt
variable "docker_host" {
  description = "Docker host address"
  default     = "unix:///var/run/docker.sock"
}

