#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# RDS SQL Server VA Config Module Variables

#------------------------------------------------------------------------------
# Database Connection Configuration
#------------------------------------------------------------------------------

variable "db_host" {
  description = "Hostname or IP address of the SQL Server database"
  type        = string
}

variable "db_port" {
  description = "Port for the SQL Server database"
  type        = number
  default     = 1433
}

variable "db_username" {
  description = "Username for the SQL Server database"
  type        = string
  default     = "rdsadmin"
}

variable "db_password" {
  description = "Password for the SQL Server user"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the SQL Server database"
  type        = string
  default     = "master"
}

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
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
}

#------------------------------------------------------------------------------
# Vulnerability Assessment Datasource Configuration
#------------------------------------------------------------------------------

variable "datasource_name" {
  description = "A unique name for the datasource on the Guardium system"
  type        = string
  default     = "rds-mssql-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "SQL Server data source onboarded via Terraform"
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
# Advanced Datasource Configuration
#------------------------------------------------------------------------------

variable "datasource_type" {
  description = "The type of datasource. For SQL Server, this should be 'MSSQL'"
  type        = string
  default     = "MSSQL"
}

variable "save_password" {
  description = "Save and encrypt database authentication credentials on the Guardium system"
  type        = bool
  default     = true
}

variable "use_ssl" {
  description = "Enable to use SSL authentication"
  type        = bool
  default     = false
}

variable "import_server_ssl_cert" {
  description = "Whether to import the server SSL certificate"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Service name for the database connection"
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
  description = "Compatibility mode (e.g., MSSQL 2000, Default)"
  type        = string
  default     = ""
}

variable "custom_url" {
  description = "Custom connection string to the datasource"
  type        = string
  default     = ""
}

variable "use_kerberos" {
  description = "Enable to use Kerberos authentication"
  type        = bool
  default     = false
}

variable "kerberos_config_name" {
  description = "Name of the Kerberos configuration in Guardium"
  type        = string
  default     = ""
}

variable "use_ldap" {
  description = "Enable to use LDAP"
  type        = bool
  default     = false
}

variable "use_external_password" {
  description = "Enable to use external password management"
  type        = bool
  default     = false
}

variable "external_password_type_name" {
  description = "External password management type"
  type        = string
  default     = ""
}

variable "cyberark_config_name" {
  description = "CyberArk configuration name"
  type        = string
  default     = ""
}

variable "cyberark_object_name" {
  description = "CyberArk object name"
  type        = string
  default     = ""
}

variable "hashicorp_config_name" {
  description = "HashiCorp Vault configuration name"
  type        = string
  default     = ""
}

variable "hashicorp_path" {
  description = "HashiCorp Vault path"
  type        = string
  default     = ""
}

variable "hashicorp_role" {
  description = "HashiCorp Vault role"
  type        = string
  default     = ""
}

variable "hashicorp_child_namespace" {
  description = "HashiCorp child namespace"
  type        = string
  default     = ""
}

variable "aws_secrets_manager_config_name" {
  description = "AWS Secrets Manager configuration name"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for Secrets Manager"
  type        = string
  default     = ""
}

variable "secret_name" {
  description = "Secret name for external password management"
  type        = string
  default     = ""
}

variable "db_instance_account" {
  description = "Database account login name used by CAS"
  type        = string
  default     = ""
}

variable "db_instance_directory" {
  description = "Directory where database software is installed"
  type        = string
  default     = ""
}