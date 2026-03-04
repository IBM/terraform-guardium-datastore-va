#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL VA Config Module - Outputs

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
  value       = azurerm_key_vault.mysql_credentials.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.mysql_credentials.id
}

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = var.sqlguard_username
}

output "va_config_completed" {
  description = "Indicates that VA configuration infrastructure is deployed"
  value       = "Azure Function infrastructure created. Function code deployment required."
}