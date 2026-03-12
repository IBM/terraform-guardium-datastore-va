#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Azure MySQL server
#------------------------------------------------------------------------------
module "azure_mysql_va_config" {
  source = "../../modules/azure-mysql"

  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
  location            = var.location

  #----------------------------------------
  # Network Configuration
  #----------------------------------------
  vnet_name                      = var.vnet_name
  function_subnet_address_prefix = var.function_subnet_address_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  mysql_server_name = var.mysql_server_name
  db_host           = var.db_host
  db_port           = var.db_port
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Firewall Configuration
  #----------------------------------------
  enable_public_access      = var.enable_public_access
  guardium_hostname         = var.guardium_hostname
  additional_firewall_rules = var.additional_firewall_rules

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  tags = var.tags
}

locals {
  azure_mysql_config = templatefile("${path.module}/templates/azureMysqlVaConf.tpl", {
    datasource_name             = var.datasource_name
    datasource_hostname         = var.db_host
    datasource_port             = var.db_port
    application                 = var.application
    datasource_description      = var.datasource_description
    sqlguard_username           = var.sqlguard_username
    sqlguard_password           = var.sqlguard_password
    severity_level              = var.severity_level
    use_ssl                     = var.use_ssl
    import_server_ssl_cert      = var.import_server_ssl_cert
    use_external_password       = var.use_external_password
    external_password_type_name = var.external_password_type_name
    azure_key_vault_config_name = var.azure_key_vault_config_name
    key_vault_name              = var.key_vault_name
    secret_name                 = var.secret_name
  })
  azure_mysql_config_json_decoded = jsondecode(local.azure_mysql_config)
  azure_mysql_config_json_encoded = jsonencode(local.azure_mysql_config)
}

#------------------------------------------------------------------------------
# Step 2: Connect the Azure MySQL server to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "azure_mysql_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.azure_mysql_config_json_encoded

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
  depends_on = [module.azure_mysql_va_config]
}