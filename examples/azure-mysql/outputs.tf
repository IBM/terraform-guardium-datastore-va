#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL with VA Example - Outputs

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.azure_mysql_va_config.function_app_name
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = module.azure_mysql_va_config.function_app_id
}

output "key_vault_name" {
  description = "Name of the Key Vault storing credentials"
  value       = module.azure_mysql_va_config.key_vault_name
}

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = module.azure_mysql_va_config.sqlguard_username
}

output "va_config_completed" {
  description = "Confirmation that VA configuration is complete"
  value       = module.azure_mysql_va_config.va_config_completed
}