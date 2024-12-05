output "webnet_id" {
  value       = docker_network.webnet.id
  description = "The ID of the webnet network"
}

output "keycloak_network_id" {
  value       = docker_network.keycloak_network.id
  description = "The ID of the Keycloak network"
}

output "monitoring_net_id" {
  value       = docker_network.monitoring_net.id
  description = "The ID of the monitoring network"
}

output "traefik_endpoint" {
  value       = "http://localhost:8082"
  description = "The Traefik dashboard endpoint"
}
