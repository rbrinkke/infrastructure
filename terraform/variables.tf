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
