#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise MySQL VA Config Module Variables

#------------------------------------------------------------------------------
# Database Connection Details
#------------------------------------------------------------------------------

variable "db_host" {
  description = "Hostname or IP address of the on-premise MySQL database (e.g., api.rr1.cp.fyre.ibm.com)"
  type        = string
}

variable "db_port" {
  description = "Port for the MySQL database"
  type        = number
  default     = 3306
}

variable "db_username" {
  description = "Username for the MySQL database (must have superuser privileges to create sqlguard user)"
  type        = string
}

variable "db_password" {
  description = "Password for the MySQL database admin user"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Guardium VA User Configuration
#------------------------------------------------------------------------------

variable "sqlguard_username" {
  description = "Username for the Guardium VA user that will be created in MySQL"
  type        = string
  default     = "sqlguard"
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Guardium Data Protection (GDP) Connection Details
#------------------------------------------------------------------------------

variable "gdp_server" {
  description = "Guardium Data Protection server hostname or IP address"
  type        = string
}

variable "gdp_username" {
  description = "Guardium Data Protection username"
  type        = string
}

variable "gdp_password" {
  description = "Guardium Data Protection password"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "OAuth client ID for Guardium API authentication"
  type        = string
}

variable "client_secret" {
  description = "OAuth client secret for Guardium API authentication"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Datasource Configuration
#------------------------------------------------------------------------------

variable "datasource_name" {
  description = "A unique name for the datasource on the Guardium system"
  type        = string
  default     = "onprem-mysql-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "On-premise MySQL data source onboarded via Terraform"
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

#------------------------------------------------------------------------------
# Advanced Connection Options
#------------------------------------------------------------------------------

variable "save_password" {
  description = "Save and encrypt database authentication credentials on the Guardium system. Default = true"
  type        = bool
  default     = true
}

variable "use_ssl" {
  description = "Enable to use SSL authentication (set to true for --ssl-mode=REQUIRED)"
  type        = bool
  default     = true
}

variable "import_server_ssl_cert" {
  description = "Whether to import the server SSL certificate"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Service name (not typically used for MySQL)"
  type        = string
  default     = ""
}

variable "shared_datasource" {
  description = "Valid values: Shared (share with other applications), Not Shared, true, false"
  type        = string
  default     = "Not Shared"
}

variable "connection_properties" {
  description = "Additional connection properties for the JDBC URL"
  type        = string
  default     = ""
}

variable "compatibility_mode" {
  description = "Compatibility mode (not typically used for MySQL)"
  type        = string
  default     = ""
}

variable "custom_url" {
  description = "Custom JDBC connection string (optional, overrides host/port if provided)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Authentication Options
#------------------------------------------------------------------------------

variable "use_kerberos" {
  description = "Enable to use Kerberos authentication"
  type        = bool
  default     = false
}

variable "kerberos_config_name" {
  description = "Name of the Kerberos configuration already defined in the Guardium system"
  type        = string
  default     = ""
}

variable "use_ldap" {
  description = "Enable to use LDAP"
  type        = bool
  default     = false
}

variable "use_external_password" {
  description = "Enable to use external password management (CyberArk, HashiCorp, AWS Secrets Manager)"
  type        = bool
  default     = false
}

variable "external_password_type_name" {
  description = "External password management type"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# CyberArk Configuration
#------------------------------------------------------------------------------

variable "cyberark_config_name" {
  description = "The name of the CyberArk configuration on your Guardium system"
  type        = string
  default     = ""
}

variable "cyberark_object_name" {
  description = "The CyberArk object name for the Guardium datasource"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# HashiCorp Vault Configuration
#------------------------------------------------------------------------------

variable "hashicorp_config_name" {
  description = "The name of the HashiCorp configuration on your Guardium system"
  type        = string
  default     = ""
}

variable "hashicorp_path" {
  description = "The custom path to access the datasource credentials"
  type        = string
  default     = ""
}

variable "hashicorp_role" {
  description = "The role name for the datasource"
  type        = string
  default     = ""
}

variable "hashicorp_child_namespace" {
  description = "HashiCorp child namespace"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# AWS Secrets Manager Configuration
#------------------------------------------------------------------------------

variable "aws_secrets_manager_config_name" {
  description = "AWS Secrets Manager configuration name (if using external password management)"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region (if using AWS Secrets Manager)"
  type        = string
  default     = ""
}

variable "secret_name" {
  description = "Secret name for external password management"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Database Instance Configuration
#------------------------------------------------------------------------------

variable "db_instance_account" {
  description = "Database account login name used by CAS"
  type        = string
  default     = ""
}

variable "db_instance_directory" {
  description = "Directory where database software is installed that will be used by CAS"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Purpose = "guardium-va-onprem-mysql"
    Owner   = "your-email@example.com"
  }
}