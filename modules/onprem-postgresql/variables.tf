#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise PostgreSQL VA Config Module Variables

variable "db_host" {
  description = "Hostname or IP address of the PostgreSQL database"
  type        = string

  validation {
    condition     = length(var.db_host) > 0
    error_message = "Database hostname cannot be empty."
  }
}

variable "db_port" {
  description = "Port for the PostgreSQL database"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "db_name" {
  description = "Name of the PostgreSQL database to connect to"
  type        = string
  default     = "postgres"

  validation {
    condition     = length(var.db_name) > 0
    error_message = "Database name cannot be empty."
  }
}

variable "db_username" {
  description = "Username for the PostgreSQL database (must have superuser privileges to create users and groups)"
  type        = string

  validation {
    condition     = length(var.db_username) > 0
    error_message = "Database username cannot be empty."
  }
}

variable "db_password" {
  description = "Password for the PostgreSQL database admin user"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) > 0
    error_message = "Database password cannot be empty."
  }
}

variable "sqlguard_username" {
  description = "Username for the Guardium VA user (will be created if it doesn't exist)"
  type        = string
  default     = "sqlguard"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_]{0,62}$", var.sqlguard_username))
    error_message = "PostgreSQL username must start with a lowercase letter or underscore, contain only lowercase letters, numbers, and underscores, and be 1-63 characters long."
  }
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user (must meet PostgreSQL security requirements)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sqlguard_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "use_ssl" {
  description = "Whether to use SSL for the database connection"
  type        = bool
  default     = false
}

variable "ssl_mode" {
  description = "SSL mode for PostgreSQL connection (disable, allow, prefer, require, verify-ca, verify-full)"
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["disable", "allow", "prefer", "require", "verify-ca", "verify-full"], var.ssl_mode)
    error_message = "SSL mode must be one of: disable, allow, prefer, require, verify-ca, verify-full."
  }
}

variable "tags" {
  description = "Tags to apply to resources (for documentation purposes)"
  type        = map(string)
  default = {
    Purpose = "guardium-va-config"
    Module  = "onprem-postgresql"
  }
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
  default     = "onprem-postgresql-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "On-premise PostgreSQL data source onboarded via Terraform"
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

variable "import_server_ssl_cert" {
  description = "Whether to import and verify the server SSL certificate. IMPORTANT: For production environments, this should be true when use_ssl is enabled to prevent man-in-the-middle attacks."
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Service name (not typically used for PostgreSQL)"
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
  description = "Compatibility mode (not typically used for PostgreSQL)"
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