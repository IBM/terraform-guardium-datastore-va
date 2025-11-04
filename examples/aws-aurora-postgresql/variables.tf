# AWS Aurora PostgreSQL with VA Example - Variables

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
  default = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "aurora-postgresql-monitoring"
}

#------------------------------------------------------------------------------
# Aurora PostgreSQL Configuration
#------------------------------------------------------------------------------
variable "db_host" {
  description = "Cluster endpoint of the Aurora PostgreSQL cluster"
  type        = string
}

variable "db_name" {
  description = "Name of the Aurora PostgreSQL database"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "Master username for the Aurora PostgreSQL cluster"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for the Aurora PostgreSQL cluster"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port for Aurora PostgreSQL cluster"
  type        = number
  default     = 5432
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "The ID of the VPC to deploy the Lambda into"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy the Lambda into"
  type        = list(string)
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
  default     = "aurora-postgresql-va"
}

variable "datasource_description" {
  description = "Description of the datasource"
  type        = string
  default     = "Aurora PostgreSQL data source onboarded via Terraform"
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

variable "datasource_type" {
  description = "Required. The type of datasource. For valid values, call create_datasource from the command line with --help=true"
  type        = string
  default     = ""
}

variable "save_password" {
  description = "Save and encrypt database authentication credentials on the Guardium system. Default = 1 (true)"
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
  description = "Required for Oracle, Informix, Db2, and IBM i. For a Db2 database, provide the database name. Otherwise, provide the service name"
  type        = string
  default     = ""
}

variable "shared_datasource" {
  description = "Valid values: Shared (share with other applications), Not Shared, true (share with other applications), false"
  type        = string
  default     = "Not Shared"
}

variable "connection_properties" {
  description = "Define conProperty if additional connection properties are needed on the JDBC URL to establish a JDBC connection with this datasource"
  type        = string
  default     = ""
}

variable "compatibility_mode" {
  description = "Valid values: Default, MSSQL 2000. Set the compatibility mode to use when monitoring a table"
  type        = string
  default     = ""
}

variable "custom_url" {
  description = "Define the connection string to the datasource. By default, the connection is made using host, port, instance, and other defined datasource parameters"
  type        = string
  default     = ""
}

variable "use_kerberos" {
  description = "Enable to use Kerberos authentication. If enabled, KerberosConfigName is required"
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
  description = "Enable to use external password management"
  type        = bool
  default     = false
}

variable "external_password_type_name" {
  description = "For valid values, call create_datasource from the command line with --help=true"
  type        = string
  default     = ""
}

variable "cyberark_config_name" {
  description = "The name of the CyberArk configuration on your Guardium system. For valid values, call create_datasource from the command line with --help=true"
  type        = string
  default     = ""
}

variable "cyberark_object_name" {
  description = "The CyberArk object name for the Guardium datasource"
  type        = string
  default     = ""
}

variable "hashicorp_config_name" {
  description = "The name of the HashiCorp configuration on your Guardium system. For valid values, call create_datasource from the command line with --help=true"
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

variable "aws_secrets_manager_config_name" {
  description = "For Amazon Web Services (AWS) systems only. This parameter is needed when authentication is externally managed by the AWS secrets manager"
  type        = string
  default     = ""
}

variable "region" {
  description = "For AWS only. For valid values, call create_datasource from the command line with --help=true"
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
  description = "Directory where database software is installed that will be used by CAS"
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