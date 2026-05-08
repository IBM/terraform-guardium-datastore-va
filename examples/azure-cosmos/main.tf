#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Azure Cosmos DB
#------------------------------------------------------------------------------
module "azure_cosmos_va_config" {
  source = "../../modules/azure-cosmos"

  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
  location            = var.location

  #----------------------------------------
  # Network Configuration
  #----------------------------------------
  vnet_name                      = var.vnet_name
  function_subnet_address_prefix = var.function_subnet_address_prefix

  #----------------------------------------
  # Cosmos DB Connection Details
  #----------------------------------------
  cosmos_account_name     = var.cosmos_account_name
  cosmos_account_endpoint = var.cosmos_endpoint
  cosmos_db_kind          = var.cosmos_db_kind
  database_name           = var.database_name

  #----------------------------------------
  # Firewall Configuration
  #----------------------------------------
  enable_public_access = var.enable_public_access
  guardium_ip_address  = var.guardium_ip_address

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  tags = var.tags
}

locals {
  azure_cosmos_config = templatefile("${path.module}/templates/azureCosmosVaConf.tpl", {
    datasource_name             = var.datasource_name
    datasource_hostname         = var.cosmos_endpoint_hostname
    datasource_port             = var.cosmos_port
    application                 = var.application
    datasource_description      = var.datasource_description
    cosmos_username             = var.cosmos_username
    cosmos_password             = var.cosmos_primary_key
    severity_level              = var.severity_level
    use_ssl                     = var.use_ssl
    import_server_ssl_cert      = var.import_server_ssl_cert
    use_external_password       = var.use_external_password
    external_password_type_name = var.external_password_type_name
    azure_key_vault_config_name = var.azure_key_vault_config_name
    key_vault_name              = var.key_vault_name
    secret_name                 = var.secret_name
    azure_subscription_id       = var.azure_subscription_id
    azure_tenant_id             = var.azure_tenant_id
    azure_client_id             = var.azure_client_id
    azure_client_secret         = var.azure_client_secret
    resource_group_name         = var.resource_group_name
    cosmos_account_name         = var.cosmos_account_name
  })
  azure_cosmos_config_json_decoded = jsondecode(local.azure_cosmos_config)
  azure_cosmos_config_json_encoded = jsonencode(local.azure_cosmos_config)
}

#------------------------------------------------------------------------------
# Step 2: Connect the Azure Cosmos DB to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "azure_cosmos_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.azure_cosmos_config_json_encoded

  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username
  gdp_port      = var.gdp_port

  #----------------------------------------
  # Vulnerability Assessment Configuration
  #----------------------------------------
  datasource_name                 = var.datasource_name
  enable_vulnerability_assessment = var.enable_vulnerability_assessment
  assessment_schedule             = var.assessment_schedule
  assessment_day                  = var.assessment_day
  assessment_time                 = var.assessment_time

  #----------------------------------------
  # Notification Configuration
  #----------------------------------------
  enable_notifications  = var.enable_notifications
  notification_emails   = var.notification_emails
  notification_severity = var.notification_severity

  #----------------------------------------
  # Tags
  #----------------------------------------
  tags = var.tags

  # Depends on the VA configuration being completed
  depends_on = [module.azure_cosmos_va_config]
}