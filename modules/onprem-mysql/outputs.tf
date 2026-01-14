#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise MySQL VA Config Module Outputs

output "datasource_name" {
  description = "Name of the datasource registered in Guardium"
  value       = var.datasource_name
}

output "datasource_host" {
  description = "Hostname of the on-premise MySQL database"
  value       = var.db_host
}

output "datasource_port" {
  description = "Port of the on-premise MySQL database"
  value       = var.db_port
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