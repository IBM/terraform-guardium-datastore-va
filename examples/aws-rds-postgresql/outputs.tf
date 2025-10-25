# AWS RDS PostgreSQL with VA Example - Outputs


output "postgresql_instance_address" {
  description = "Address of the RDS PostgreSQL instance"
  value       = var.db_host
}

output "postgresql_instance_port" {
  description = "Port of the RDS PostgreSQL instance"
  value       = var.db_port
}

output "postgresql_instance_name" {
  description = "Name of the PostgreSQL database"
  value       = var.db_name
}

output "postgresql_instance_username" {
  description = "Username for the PostgreSQL database"
  value       = var.db_username
}

# VPC and Subnet Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = var.subnet_ids
}

# VA Configuration Outputs
output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = "sqlguard"
}

output "va_config_status" {
  description = "Status of the VA configuration"
  value       = "Completed"
}

# Guardium Data Protection Connection Outputs
output "gdp_datasource_name" {
  description = "Name of the registered data source in Guardium"
  value       = var.datasource_name
}

output "gdp_datasource_type" {
  description = "Type of the registered data source"
#   value       = module.postgresql_gdp_connection.*.datasource_type
  value = var.datasource_type
}

output "gdp_vulnerability_assessment_enabled" {
  description = "Whether vulnerability assessment is enabled for the data source"
  value       = var.enable_vulnerability_assessment
}

output "gdp_assessment_schedule" {
  description = "Schedule for vulnerability assessments"
  value       = var.assessment_schedule
}

output "gdp_notifications_enabled" {
  description = "Whether notifications are enabled for assessment results"
  value       = var.enable_notifications
}

output "gdp_notification_recipients" {
  description = "Email addresses that will receive notifications"
  value       = var.notification_emails
}

output "gdp_server" {
  description = "Hostname of the Guardium Data Protection server"
  value       = module.postgresql_gdp_connection.*.guardium_server
}