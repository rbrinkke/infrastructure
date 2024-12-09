output "traefik_endpoint" {
  value       = "http://traefik.example.com"
  description = "The Traefik dashboard endpoint"
}

output "prometheus_endpoint" {
  value       = "http://prometheus.example.com"
  description = "The Prometheus endpoint"
}

output "grafana_endpoint" {
  value       = "http://grafana.example.com"
  description = "The Grafana endpoint"
}

output "cadvisor_endpoint" {
  value       = "http://cadvisor.example.com"
  description = "The cAdvisor endpoint"
}