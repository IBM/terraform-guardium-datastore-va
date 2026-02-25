#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS Neptune with VA Example - Outputs

output "neptune_cluster_endpoint" {
  description = "Endpoint of the Neptune cluster"
  value       = var.neptune_cluster_endpoint
}

output "neptune_cluster_port" {
  description = "Port of the Neptune cluster"
  value       = var.neptune_cluster_port
}

output "neptune_cluster_identifier" {
  description = "Identifier of the Neptune cluster"
  value       = var.neptune_cluster_identifier
}

output "neptune_username" {
  description = "Username for the Neptune database"
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

output "lambda_function_name" {
  description = "Name of the Lambda function used for VA configuration"
  value       = module.neptune_va_config.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.neptune_va_config.lambda_function_arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.neptune_va_config.secret_arn
}

# Guardium Data Protection Connection Outputs
output "gdp_datasource_name" {
  description = "Name of the registered data source in Guardium"
  value       = var.datasource_name
}

output "gdp_datasource_type" {
  description = "Type of the registered data source"
  value       = "Amazon Neptune"
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
  value       = var.enable_vulnerability_assessment ? module.neptune_gdp_connection[0].guardium_server : null
}