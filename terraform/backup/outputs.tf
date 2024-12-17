# backup/outputs.tf

output "backup_service_name" {
  description = "Name of the backup service container"
  value       = docker_container.backup_service.name
}

output "backup_service_id" {
  description = "ID of the backup service container"
  value       = docker_container.backup_service.id
}
