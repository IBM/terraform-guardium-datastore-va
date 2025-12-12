#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# RDS SQL Server VA Config Module Outputs

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing SQL Server credentials"
  value       = aws_secretsmanager_secret.mssql_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.mssql_credentials.name
}

output "secret_id" {
  description = "ID of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.mssql_credentials.id
}

output "db_host" {
  description = "SQL Server database host"
  value       = var.db_host
}

output "db_port" {
  description = "SQL Server database port"
  value       = var.db_port
}

output "db_username" {
  description = "SQL Server database username"
  value       = var.db_username
}

output "database_name" {
  description = "SQL Server database name"
  value       = var.database_name
}

output "datasource_name" {
  description = "Name of the datasource for Guardium registration"
  value       = var.datasource_name
}