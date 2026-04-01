#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB VA Config Module - Main Configuration

locals {
  # Secret names using the name_prefix for consistency
  secret_name = "${var.name_prefix}-azure-cosmos-va-credentials"
  # Generate short unique suffix for resource names (max 24 chars for Key Vault and Storage)
  # Key Vault: alphanumeric and dashes, 3-24 chars - add random suffix to avoid conflicts
  kv_name = substr("${replace(var.name_prefix, "_", "-")}-cosmos-kv-${random_string.kv_suffix.result}", 0, 24)
  # Storage Account: lowercase alphanumeric only, 3-24 chars
  storage_name = substr(replace(lower("${var.name_prefix}cosmosva${random_string.storage_suffix.result}"), "/[^a-z0-9]/", ""), 0, 24)
  # Function package
  zip_file = "${path.module}/files/function.zip"
  zip_hash = filesha256(local.zip_file)
}

# Generate random suffix for Key Vault name (globally unique)
resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate random suffix for Storage Account name
resource "random_string" "storage_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Resolve Guardium hostname to IP address using DNS lookup (only if public access enabled)
data "dns_a_record_set" "guardium_ip" {
  count = var.enable_public_access && var.guardium_hostname != "" ? 1 : 0
  host  = var.guardium_hostname
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get Cosmos DB account keys
data "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  resource_group_name = var.resource_group_name
}

# Create Azure Key Vault for storing credentials
resource "azurerm_key_vault" "cosmos_credentials" {
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

# Store Cosmos DB credentials in Key Vault
resource "azurerm_key_vault_secret" "cosmos_credentials" {
  name = local.secret_name
  value = jsonencode({
    endpoint       = var.cosmos_account_endpoint
    primary_key    = data.azurerm_cosmosdb_account.cosmos.primary_key
    database_name  = var.database_name
    cosmos_db_kind = var.cosmos_db_kind
    account_name   = var.cosmos_account_name
  })
  key_vault_id = azurerm_key_vault.cosmos_credentials.id

  depends_on = [azurerm_key_vault.cosmos_credentials]
}

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
  name                = "${var.name_prefix}-cosmos-va-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "EP1" # Elastic Premium plan (quota approved)

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

# Create Azure Function App
resource "azurerm_linux_function_app" "va_config_function" {
  name                       = "${var.name_prefix}-cosmos-va-func"
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
    "KEY_VAULT_NAME"           = azurerm_key_vault.cosmos_credentials.name
    "SECRET_NAME"              = local.secret_name
    "AZURE_SUBSCRIPTION_ID"    = data.azurerm_client_config.current.subscription_id
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Configure VNet integration for Function App
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  app_service_id = azurerm_linux_function_app.va_config_function.id
  subnet_id      = azurerm_subnet.function_subnet.id

  depends_on = [azurerm_linux_function_app.va_config_function]
}

# Grant Function App access to Key Vault
resource "azurerm_key_vault_access_policy" "function_access" {
  key_vault_id = azurerm_key_vault.cosmos_credentials.id
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

# Configure Cosmos DB firewall rules to allow Guardium access (only if public access enabled)
# Note: Cosmos DB uses IP firewall rules, not separate firewall rule resources
resource "null_resource" "cosmos_firewall_guardium" {
  count = var.enable_public_access && var.guardium_ip_address != "" ? 1 : 0

  triggers = {
    guardium_ip = var.guardium_ip_address
    account_id  = data.azurerm_cosmosdb_account.cosmos.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Get current IP rules
      CURRENT_IPS=$(az cosmosdb show --name ${var.cosmos_account_name} --resource-group ${var.resource_group_name} --query "ipRules[].ipAddressOrRange" -o tsv | tr '\n' ',')
      
      # Add Guardium IP if not already present
      if [[ ! "$CURRENT_IPS" =~ "${var.guardium_ip_address}" ]]; then
        NEW_IPS="${var.guardium_ip_address}"
        if [ ! -z "$CURRENT_IPS" ]; then
          NEW_IPS="$CURRENT_IPS,$NEW_IPS"
        fi
        
        az cosmosdb update \
          --name ${var.cosmos_account_name} \
          --resource-group ${var.resource_group_name} \
          --ip-range-filter "$NEW_IPS"
      fi
    EOT
  }

  depends_on = [data.azurerm_cosmosdb_account.cosmos]
}

# Note: Function invocation should be done manually after verifying the function is deployed
# To invoke the function manually:
# 1. Wait for the function to appear in Azure Portal (may take 5-10 minutes)
# 2. Get the function key: az functionapp keys list --resource-group <rg> --name <func-name> --query "functionKeys.default" -o tsv
# 3. Invoke: curl -X POST "https://<func-name>.azurewebsites.net/api/CosmosVAConfig?code=<key>" -H "Content-Type: application/json" -d '{}'