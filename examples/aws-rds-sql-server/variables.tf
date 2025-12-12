#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# AWS RDS SQL Server with VA Example - Variables

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "rds-mssql-va"
}

#------------------------------------------------------------------------------
# RDS SQL Server Configuration
#------------------------------------------------------------------------------

variable "db_host" {
  description = "Hostname of the SQL Server database"
  type        = string
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

variable "db_port" {
  description = "Port for SQL Server database"
  type        = number
  default     = 1433
}

variable "database_name" {
  description = "Name of the SQL Server database"
  type        = string
  default     = "master"
}

#------------------------------------------------------------------------------
# VA User Configuration
#------------------------------------------------------------------------------

variable "sqlguard_username" {
  description = "Username for the sqlguard VA user to be created"
  type        = string
  default     = "sqlguard"
}

variable "sqlguard_password" {
  description = "Password for the sqlguard VA user"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Lambda Configuration
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where Lambda function will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Lambda function (should be private subnets with NAT gateway)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID of the RDS SQL Server instance"
  type        = string
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
  description = "The client secret output from grdapi register_oauth_client"
  type        = string
  sensitive   = true
}

#------------------------------------------------------------------------------
# Guardium Data Source Registration Configuration
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
  description = "The type of datasource (MSSQL for SQL Server)"
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
  description = "Valid values: Shared, Not Shared, true, false"
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