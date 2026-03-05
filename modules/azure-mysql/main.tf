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
  # Function package
  zip_file = "${path.module}/files/function.zip"
  zip_hash = filesha256(local.zip_file)
}

# Resolve Guardium hostname to IP address using DNS lookup (only if public access enabled)
data "dns_a_record_set" "guardium_ip" {
  count = var.enable_public_access ? 1 : 0
  host  = var.guardium_hostname
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

# Create App Service Plan for Azure Function (Premium EP1 for VNet integration)
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.name_prefix}-mysql-va-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "EP1" # Elastic Premium plan (supports VNet integration)

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
# Create subnet for Function App VNet integration
resource "azurerm_subnet" "function_subnet" {
  name                 = "${var.name_prefix}-function-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.function_subnet_address_prefix]

  delegation {
    name = "function-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Configure VNet integration for Function App
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  app_service_id = azurerm_linux_function_app.va_config_function.id
  subnet_id      = azurerm_subnet.function_subnet.id

  depends_on = [azurerm_linux_function_app.va_config_function]
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

# Deploy function code using null_resource and Azure CLI with remote build
resource "null_resource" "deploy_function" {
  triggers = {
    function_code_hash = local.zip_hash
    function_app_id    = azurerm_linux_function_app.va_config_function.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      az functionapp deployment source config-zip \
        --resource-group ${var.resource_group_name} \
        --name ${azurerm_linux_function_app.va_config_function.name} \
        --src ${local.zip_file} \
        --build-remote true
    EOT
  }

  depends_on = [
    azurerm_linux_function_app.va_config_function,
    azurerm_key_vault_access_policy.function_access
  ]
}

# Note: Function invocation should be done manually after verifying the function is deployed
# To invoke the function manually:
# 1. Wait for the function to appear in Azure Portal (may take 5-10 minutes)
# 2. Get the function key: az functionapp keys list --resource-group <rg> --name <func-name> --query "functionKeys.default" -o tsv
# 3. Invoke: curl -X POST "https://<func-name>.azurewebsites.net/api/MySQLVAConfig?code=<key>" -H "Content-Type: application/json" -d '{}'
# Create firewall rule to allow Guardium server access (only if public access enabled)
resource "azurerm_mysql_flexible_server_firewall_rule" "guardium_access" {
  count               = var.enable_public_access ? 1 : 0
  name                = "AllowGuardiumServer"
  resource_group_name = var.resource_group_name
  server_name         = var.mysql_server_name
  start_ip_address    = data.dns_a_record_set.guardium_ip[0].addrs[0]
  end_ip_address      = data.dns_a_record_set.guardium_ip[0].addrs[0]
}

# Create firewall rule to allow Azure services (for Function App)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.resource_group_name
  server_name         = var.mysql_server_name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create additional firewall rules for custom IP ranges
resource "azurerm_mysql_flexible_server_firewall_rule" "additional_rules" {
  for_each            = var.additional_firewall_rules
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = var.mysql_server_name
  start_ip_address    = each.value.start_ip
  end_ip_address      = each.value.end_ip
}