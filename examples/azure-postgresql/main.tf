#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure PostgreSQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Azure PostgreSQL server
#------------------------------------------------------------------------------
module "azure_postgresql_va_config" {
  source = "../../modules/azure-postgresql"

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
  postgresql_server_name = var.postgresql_server_name
  db_host                = var.db_host
  db_port                = var.db_port
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password

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
  azure_postgresql_config = sensitive(templatefile("${path.module}/templates/azurePostgresqlVaConf.tpl", {
    datasource_name        = "${var.name_prefix}-azure-postgresql-va"
    datasource_hostname    = var.db_host
    datasource_port        = var.db_port
    application            = "Azure PostgreSQL VA"
    datasource_description = "Azure PostgreSQL Flexible Server with VA configuration"
    db_name                = var.db_name
    sqlguard_username      = var.sqlguard_username
    sqlguard_password      = sensitive(var.sqlguard_password)
  }))
}

#------------------------------------------------------------------------------
# Step 2: Connect the Azure PostgreSQL server to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
# Note: This example demonstrates the VA configuration infrastructure.
# The actual GDP connection would be configured separately using the
# guardium-data-protection provider once the datasource template is finalized.
#
# Example usage (commented out - requires guardium-data-protection provider module):
# module "azure_postgresql_gdp_connection" {
#   source = "IBM/gdp/guardium//modules/connect-datasource-to-va"
#
#   datasource_payload = local.azure_postgresql_config
#
#   gdp_server   = var.gdp_host
#   gdp_port     = var.gdp_port
#   gdp_username = var.gdp_username
#   gdp_password = var.gdp_password
#
#   depends_on = [module.azure_postgresql_va_config]
# }
