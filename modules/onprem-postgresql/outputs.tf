#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise PostgreSQL VA Config Module Outputs

output "datasource_name" {
  description = "Name of the datasource registered in Guardium"
  value       = var.datasource_name
}

output "datasource_host" {
  description = "Hostname of the on-premise PostgreSQL database"
  value       = var.db_host
}

output "datasource_port" {
  description = "Port of the on-premise PostgreSQL database"
  value       = var.db_port
}

output "sqlguard_username" {
  description = "Username for Guardium VA"
  value       = var.sqlguard_username
}

output "db_host" {
  description = "PostgreSQL database hostname"
  value       = var.db_host
}

output "db_port" {
  description = "PostgreSQL database port"
  value       = var.db_port
}

output "connection_string" {
  description = "PostgreSQL connection string for Guardium (without password)"
  value       = "postgresql://${var.sqlguard_username}@${var.db_host}:${var.db_port}/${var.db_name}?sslmode=${var.ssl_mode}"
}

output "va_config_completed" {
  description = "VA configuration status"
  value       = true
}

output "vulnerability_assessment_enabled" {
  description = "Whether vulnerability assessment is enabled"
  value       = var.enable_vulnerability_assessment
}

output "assessment_schedule" {
  description = "Schedule for vulnerability assessments"
  value       = var.enable_vulnerability_assessment ? var.assessment_schedule : "disabled"
}

output "ssl_enabled" {
  description = "Whether SSL is enabled for the connection"
  value       = var.use_ssl
}

output "gdp_connection_status" {
  description = "Status of the Guardium Data Protection connection"
  value       = var.enable_vulnerability_assessment ? "configured" : "not configured"
}