#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL VA Config Module - Main Configuration

locals {
  # Secret names using the name_prefix for consistency
  secret_name = "${var.name_prefix}-azure-mysql-va-password"
  # Generate short unique suffix for resource names (max 24 chars for Key Vault and Storage)
  # Key Vault: alphanumeric and dashes, 3-24 chars
  kv_name = substr("${replace(var.name_prefix, "_", "-")}-kv", 0, 24)
  # Storage Account: lowercase alphanumeric only, 3-24 chars
  storage_name = substr(replace(lower("${var.name_prefix}mysqlva"), "/[^a-z0-9]/", ""), 0, 24)
}

# Create Azure Key Vault for storing credentials
resource "azurerm_key_vault" "mysql_credentials" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  tags = var.tags
}

# Store MySQL credentials in Key Vault
resource "azurerm_key_vault_secret" "mysql_credentials" {
  name = local.secret_name
  value = jsonencode({
    username          = var.db_username
    password          = var.db_password
    endpoint          = var.db_host
    port              = var.db_port
    database          = var.db_name
    sqlguard_username = var.sqlguard_username
    sqlguard_password = var.sqlguard_password
  })
  key_vault_id = azurerm_key_vault.mysql_credentials.id

  depends_on = [azurerm_key_vault.mysql_credentials]
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Create Storage Account for Azure Function
resource "azurerm_storage_account" "function_storage" {
  name                     = local.storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# Create App Service Plan for Azure Function
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.name_prefix}-mysql-va-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan

  tags = var.tags
}

# Create Azure Function App
resource "azurerm_linux_function_app" "va_config_function" {
  name                       = "${var.name_prefix}-mysql-va-func"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "KEY_VAULT_NAME"           = azurerm_key_vault.mysql_credentials.name
    "SECRET_NAME"              = local.secret_name
    "AZURE_SUBSCRIPTION_ID"    = data.azurerm_client_config.current.subscription_id
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant Function App access to Key Vault
resource "azurerm_key_vault_access_policy" "function_access" {
  key_vault_id = azurerm_key_vault.mysql_credentials.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.va_config_function.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [azurerm_linux_function_app.va_config_function]
}

# Note: In a production environment, you would deploy the actual function code
# For now, this creates the infrastructure. The function code would need to:
# 1. Connect to the MySQL server using credentials from Key Vault
# 2. Create the sqlguard user with appropriate permissions
# 3. Configure the database for vulnerability assessment

# Placeholder for function deployment
# In practice, you would use azurerm_function_app_function or deploy via Azure CLI/GitHub Actions