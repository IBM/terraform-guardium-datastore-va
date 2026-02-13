#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS RDS DocumentDB with VA Example - Outputs

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = module.documentdb_va_config.sqlguard_username
}

output "sqlguard_password" {
  description = "Password for the Guardium VA user"
  value       = module.documentdb_va_config.sqlguard_password
  sensitive   = true
}

output "datasource_name" {
  description = "Name of the datasource registered in Guardium"
  value       = var.datasource_name
}