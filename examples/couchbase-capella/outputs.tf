#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Couchbase Capella with VA Example - Outputs

output "cluster_endpoint" {
  description = "Endpoint of the Couchbase Capella cluster"
  value       = var.cluster_endpoint
}

output "cluster_port" {
  description = "Port of the Couchbase Capella cluster"
  value       = var.cluster_port
}

output "bucket_name" {
  description = "Name of the Couchbase bucket"
  value       = var.bucket_name
}

output "admin_username" {
  description = "Admin username for Couchbase Capella"
  value       = var.admin_username
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
  value       = var.sqlguard_username
}

output "va_config_status" {
  description = "Status of the VA configuration"
  value       = "Completed"
}

output "lambda_function_name" {
  description = "Name of the Lambda function used for VA configuration"
  value       = module.couchbase_capella_va_config.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.couchbase_capella_va_config.lambda_function_arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.couchbase_capella_va_config.secret_arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = module.couchbase_capella_va_config.secret_name
}

# Guardium Data Protection Connection Outputs
output "gdp_datasource_name" {
  description = "Name of the registered data source in Guardium"
  value       = var.datasource_name
}

output "gdp_datasource_type" {
  description = "Type of the registered data source"
  value       = "Couchbase Capella"
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
  value       = var.enable_vulnerability_assessment ? module.couchbase_capella_gdp_connection[0].guardium_server : null
}
