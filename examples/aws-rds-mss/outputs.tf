#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# AWS RDS SQL Server with VA Example - Outputs

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing SQL Server credentials"
  value       = module.mssql_va_config.secret_arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = module.mssql_va_config.secret_name
}

output "mssql_instance_address" {
  description = "SQL Server instance address"
  value       = module.mssql_va_config.db_host
}

output "mssql_instance_port" {
  description = "SQL Server instance port"
  value       = module.mssql_va_config.db_port
}

output "mssql_instance_username" {
  description = "SQL Server instance username"
  value       = module.mssql_va_config.db_username
}

output "datasource_name" {
  description = "Name of the datasource registered with Guardium"
  value       = var.datasource_name
}

output "gdp_server" {
  description = "Guardium server address"
  value       = var.gdp_server
}

output "gdp_vulnerability_assessment_enabled" {
  description = "Whether vulnerability assessment is enabled"
  value       = var.enable_vulnerability_assessment
}

output "gdp_assessment_schedule" {
  description = "Vulnerability assessment schedule"
  value       = var.assessment_schedule
}

output "gdp_notifications_enabled" {
  description = "Whether notifications are enabled"
  value       = var.enable_notifications
}

output "gdp_notification_recipients" {
  description = "List of notification recipients"
  value       = var.notification_emails
}

output "va_config_status" {
  description = "Status of VA configuration"
  value       = "Completed"
}