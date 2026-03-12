#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL with VA Example - Variables

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "canadacentral"
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
  default     = "azure-mysql-monitoring"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------
variable "vnet_name" {
  description = "Name of the existing VNet where MySQL server is deployed"
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

variable "guardium_hostname" {
  description = "Hostname or IP address of the Guardium server (will be resolved to IP for firewall rules)"
  type        = string
  default     = ""
}

variable "additional_firewall_rules" {
  description = "Additional firewall rules to allow access from specific IP ranges"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Azure MySQL Configuration
#------------------------------------------------------------------------------
variable "mysql_server_name" {
  description = "Name of the Azure MySQL Flexible Server"
  type        = string
}

variable "db_host" {
  description = "FQDN of the Azure MySQL Flexible Server"
  type        = string
}

variable "db_name" {
  description = "Name of the Azure MySQL database"
  type        = string
  default     = "mysql"
}

variable "db_username" {
  description = "Admin username for the Azure MySQL server"
  type        = string
  default     = "mysqladmin"
}

variable "db_password" {
  description = "Admin password for the Azure MySQL server"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port for Azure MySQL server"
  type        = number
  default     = 3306
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
  default     = "azure-mysql-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "Azure MySQL data source onboarded via Terraform"
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

# VA Configuration Outputs
variable "sqlguard_username" {
  description = "Username for the Guardium VA user"
  type        = string
  default     = "sqlguard"
}

# VA Configuration Outputs
variable "sqlguard_password" {
  description = "Password for the Guardium VA user"
  type        = string
  sensitive   = true
}