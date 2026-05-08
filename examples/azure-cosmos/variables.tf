#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB with VA Example - Variables

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "azure-cosmos-monitoring"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------
variable "vnet_name" {
  description = "Name of the existing VNet where Cosmos DB is deployed"
  type        = string
}

variable "function_subnet_address_prefix" {
  description = "Address prefix for the Function App subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_public_access" {
  description = "Enable public network access firewall rules. Set to false for production (use Private Link/VPN instead)"
  type        = bool
  default     = true
}

variable "guardium_ip_address" {
  description = "IP address of the Guardium server for firewall rules (CIDR format, e.g., 203.0.113.10/32)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Azure Cosmos DB Configuration
#------------------------------------------------------------------------------
variable "cosmos_account_name" {
  description = "Name of the Azure Cosmos DB account"
  type        = string
}

variable "cosmos_endpoint" {
  description = "Endpoint URL of the Azure Cosmos DB account (e.g., https://myaccount.documents.azure.com:443/)"
  type        = string
}

variable "cosmos_endpoint_hostname" {
  description = "Hostname of the Cosmos DB endpoint (without https:// and port)"
  type        = string
}

variable "cosmos_db_kind" {
  description = "Cosmos DB API kind (GlobalDocumentDB for SQL API, MongoDB for MongoDB API)"
  type        = string
  default     = "GlobalDocumentDB"
}

variable "cosmos_primary_key" {
  description = "Primary key for the Azure Cosmos DB account"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the Cosmos DB database"
  type        = string
  default     = "testdb"
}

variable "container_name" {
  description = "Name of the Cosmos DB container"
  type        = string
  default     = "testcontainer"
}

variable "cosmos_port" {
  description = "Port for Azure Cosmos DB"
  type        = number
  default     = 443
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID for Resource Manager authentication"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID for Resource Manager authentication"
  type        = string
}

variable "azure_client_id" {
  description = "Azure Client ID (Service Principal Application ID) for Resource Manager authentication"
  type        = string
}

variable "azure_client_secret" {
  description = "Azure Client Secret (Service Principal Password) for Resource Manager authentication"
  type        = string
  sensitive   = true
}

variable "cosmos_username" {
  description = "Username for Cosmos DB (typically the account name or primary key identifier)"
  type        = string
  default     = "cosmosdb"
}

#------------------------------------------------------------------------------
# Guardium Data Protection (GDP) Connection Configuration
#------------------------------------------------------------------------------

variable "gdp_server" {
  description = "The hostname or IP address of the Guardium server"
  type        = string
}

variable "gdp_port" {
  description = "The port of the Guardium server"
  type        = string
  default     = "8443"
}

variable "gdp_username" {
  description = "The username to login to Guardium"
  type        = string
}

variable "gdp_password" {
  description = "The password for logging in to Guardium"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "The client ID used to create the GDP register_oauth_client client_secret"
  type        = string
  default     = "client1"
}

variable "client_secret" {
  description = "The client secret output from grdapi register_oauth_client client_id=client1 grant_types=password"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Guardium Data Source Registration Configuration
#------------------------------------------------------------------------------

variable "datasource_name" {
  description = "A unique name for the datasource on the Guardium system"
  type        = string
  default     = "azure-cosmos-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "Azure Cosmos DB data source onboarded via Terraform"
}

variable "application" {
  description = "Application type for the datasource"
  type        = string
  default     = "Security Assessment"
}

variable "severity_level" {
  description = "Severity classification for the datasource (LOW, NONE, MED, HIGH)"
  type        = string
  default     = "MED"
}

#------------------------------------------------------------------------------
# Vulnerability Assessment Schedule Configuration
#------------------------------------------------------------------------------

variable "enable_vulnerability_assessment" {
  description = "Whether to enable vulnerability assessment for the data source"
  type        = bool
  default     = true
}

variable "assessment_schedule" {
  description = "Schedule for vulnerability assessments (e.g., daily, weekly, monthly)"
  type        = string
  default     = "weekly"
}

variable "assessment_day" {
  description = "Day to run the assessment (e.g., Monday, 1)"
  type        = string
  default     = "Monday"
}

variable "assessment_time" {
  description = "Time to run the assessment in 24-hour format (e.g., 02:00)"
  type        = string
  default     = "02:00"
}

#------------------------------------------------------------------------------
# Notification Configuration
#------------------------------------------------------------------------------

variable "enable_notifications" {
  description = "Whether to enable notifications for assessment results"
  type        = bool
  default     = true
}

variable "notification_emails" {
  description = "List of email addresses to notify about assessment results"
  type        = list(string)
  default     = []
}

variable "notification_severity" {
  description = "Minimum severity level for notifications (HIGH, MED, LOW, NONE)"
  type        = string
  default     = "HIGH"
}

variable "use_ssl" {
  description = "Enable to use SSL authentication"
  type        = bool
  default     = true
}

variable "import_server_ssl_cert" {
  description = "Whether to import the server SSL certificate"
  type        = bool
  default     = true
}

variable "use_external_password" {
  description = "Enable to use external password management"
  type        = bool
  default     = false
}

variable "external_password_type_name" {
  description = "For valid values, call create_datasource from the command line with --help=true"
  type        = string
  default     = ""
}

variable "azure_key_vault_config_name" {
  description = "For Azure systems only. This parameter is needed when authentication is externally managed by Azure Key Vault"
  type        = string
  default     = ""
}

variable "key_vault_name" {
  description = "Azure Key Vault name for external password management"
  type        = string
  default     = ""
}

variable "secret_name" {
  description = "Secret name for external password management"
  type        = string
  default     = ""
}