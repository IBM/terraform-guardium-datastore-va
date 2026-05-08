#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB with VA Example - Outputs

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.azure_cosmos_va_config.function_app_name
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = module.azure_cosmos_va_config.function_app_id
}

output "key_vault_name" {
  description = "Name of the Key Vault storing credentials"
  value       = module.azure_cosmos_va_config.key_vault_name
}

output "va_config_completed" {
  description = "Confirmation that VA configuration is complete"
  value       = module.azure_cosmos_va_config.va_config_completed
}

output "cosmos_datasource_config" {
  description = "Cosmos DB datasource configuration for Guardium"
  value       = local.azure_cosmos_config_json_decoded
  sensitive   = true
}