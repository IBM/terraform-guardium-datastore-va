#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure PostgreSQL VA Configuration Example - Outputs

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.azure_postgresql_va_config.function_app_name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Azure Function App"
  value       = module.azure_postgresql_va_config.function_app_default_hostname
}

output "key_vault_name" {
  description = "Name of the Key Vault storing credentials"
  value       = module.azure_postgresql_va_config.key_vault_name
}

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = module.azure_postgresql_va_config.sqlguard_username
}

output "guardium_resolved_ip" {
  description = "Resolved IP address of the Guardium server (added to PostgreSQL firewall)"
  value       = module.azure_postgresql_va_config.guardium_resolved_ip
}

output "firewall_rules_created" {
  description = "Status of firewall rule creation"
  value       = module.azure_postgresql_va_config.firewall_rules_created
}

output "va_config_completed" {
  description = "VA configuration status"
  value       = module.azure_postgresql_va_config.va_config_completed
}

output "guardium_datasource_config" {
  description = "Guardium datasource configuration (for reference)"
  value       = local.azure_postgresql_config
  sensitive   = true
}
