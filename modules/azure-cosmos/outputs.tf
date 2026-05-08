#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB VA Config Module - Outputs

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = azurerm_linux_function_app.va_config_function.name
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = azurerm_linux_function_app.va_config_function.id
}

output "function_app_default_hostname" {
  description = "Default hostname of the Azure Function App"
  value       = azurerm_linux_function_app.va_config_function.default_hostname
}

output "key_vault_name" {
  description = "Name of the Key Vault storing credentials"
  value       = azurerm_key_vault.cosmos_credentials.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.cosmos_credentials.id
}

output "cosmos_account_name" {
  description = "Name of the Cosmos DB account"
  value       = var.cosmos_account_name
}

output "cosmos_account_endpoint" {
  description = "Endpoint URL of the Cosmos DB account"
  value       = var.cosmos_account_endpoint
}

output "database_name" {
  description = "Name of the Cosmos DB database"
  value       = var.database_name
}

output "cosmos_db_kind" {
  description = "API kind of the Cosmos DB account"
  value       = var.cosmos_db_kind
}

output "va_config_completed" {
  description = "Indicates that VA configuration infrastructure is deployed"
  value       = "Azure Function infrastructure created. Function code deployment required."
}

output "guardium_resolved_ip" {
  description = "Resolved IP address of the Guardium server (added to Cosmos DB firewall)"
  value       = var.enable_public_access && var.guardium_hostname != "" ? try(data.dns_a_record_set.guardium_ip[0].addrs[0], "DNS resolution failed") : "N/A - Public access disabled"
}

output "firewall_rules_created" {
  description = "Indicates that firewall rules have been created for Guardium access"
  value       = var.enable_public_access && var.guardium_ip_address != "" ? "Firewall rule created for Guardium IP: ${var.guardium_ip_address}" : "Public access disabled - Guardium must connect via Private Link/VPN"
}

output "connection_info" {
  description = "Connection information for Guardium configuration"
  value = {
    endpoint      = var.cosmos_account_endpoint
    database_name = var.database_name
    api_kind      = var.cosmos_db_kind
  }
}