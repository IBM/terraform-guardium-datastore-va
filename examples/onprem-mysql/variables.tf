#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise MySQL VA Example - Variables

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
  description = "Username for the MySQL database (must have superuser privileges)"
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
  description = "Username for the Guardium VA user"
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

variable "gdp_port" {
  description = "The port of the Guardium server"
  type        = string
  default     = "8443"
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
# SSL Configuration
#------------------------------------------------------------------------------

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