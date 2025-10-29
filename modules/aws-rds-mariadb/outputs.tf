# RDS PostgreSQL VA Config Module Outputs

output "sqlguard_username" {
  description = "Username for the Guardium user"
  value       = local.gdmmonitor_username
}

output "sqlguard_password" {
  description = "Password for the sqlguard user"
  value       = var.gdmmonitor_password
  sensitive   = true
}