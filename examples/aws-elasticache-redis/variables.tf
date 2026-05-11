-e #
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS ElastiCache Redis with Vulnerability Assessment Example - Variables

#----------------------------------------
# AWS Configuration
#----------------------------------------
variable "aws_region" {
  description = "AWS region where ElastiCache Redis is deployed"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

#----------------------------------------
# Guardium Data Protection Connection Configuration
#----------------------------------------
variable "gdp_server" {
  description = "Hostname or IP address of the Guardium Data Protection server"
  type        = string
}

variable "gdp_port" {
  description = "Port for Guardium Data Protection API connection"
  type        = number
  default     = 8443
}

variable "guardium_username" {
  description = "Username for Guardium API authentication"
  type        = string
}

variable "guardium_password" {
  description = "Password for Guardium API authentication"
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
}

#----------------------------------------
# ElastiCache Redis Configuration
#----------------------------------------
variable "elasticache_cluster_id" {
  description = "ElastiCache Redis cluster identifier"
  type        = string
}

variable "elasticache_endpoint" {
  description = "ElastiCache Redis primary endpoint (without port)"
  type        = string
}

variable "elasticache_port" {
  description = "ElastiCache Redis port"
  type        = number
  default     = 6379
}

variable "elasticache_redis_datasource_name" {
  description = "Name to register the ElastiCache Redis datasource in Guardium"
  type        = string
  default     = "aws-elasticache-redis-va-example"
}

variable "elasticache_redis_description" {
  description = "Description for the ElastiCache Redis datasource in Guardium"
  type        = string
  default     = "AWS ElastiCache Redis with Vulnerability Assessment"
}

#----------------------------------------
# Datasource Configuration
#----------------------------------------
variable "application" {
  description = "Application type for the datasource (e.g., Security Assessment, Audit Task)"
  type        = string
  default     = "Security Assessment"
}

variable "severity_level" {
  description = "Severity classification for the datasource (LOW, NONE, MED, HIGH)"
  type        = string
  default     = "MED"

  validation {
    condition     = contains(["LOW", "NONE", "MED", "HIGH"], var.severity_level)
    error_message = "The severity_level must be one of: LOW, NONE, MED, HIGH."
  }
}

#----------------------------------------
# Vulnerability Assessment Configuration
#----------------------------------------
variable "enable_vulnerability_assessment" {
  description = "Whether to enable vulnerability assessment for ElastiCache Redis"
  type        = bool
  default     = true
}

variable "assessment_schedule" {
  description = "Schedule for vulnerability assessments (DAILY, WEEKLY, MONTHLY)"
  type        = string
  default     = "WEEKLY"

  validation {
    condition     = contains(["DAILY", "WEEKLY", "MONTHLY"], var.assessment_schedule)
    error_message = "Assessment schedule must be one of: DAILY, WEEKLY, MONTHLY."
  }
}

variable "assessment_day" {
  description = "Day for vulnerability assessments (e.g., Monday, Tuesday)"
  type        = string
  default     = "Monday"
}

variable "assessment_time" {
  description = "Time for vulnerability assessments in 24-hour format (HH:MM)"
  type        = string
  default     = "00:00"
}

#----------------------------------------
# Notification Configuration
#----------------------------------------
variable "enable_notifications" {
  description = "Whether to enable notifications for vulnerability assessment results"
  type        = bool
  default     = true
}

variable "notification_emails" {
  description = "Email addresses to receive vulnerability assessment notifications"
  type        = list(string)
  default     = []
}

variable "notification_severity" {
  description = "Minimum severity level for notifications (LOW, MEDIUM, HIGH, CRITICAL)"
  type        = string
  default     = "HIGH"

  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH", "CRITICAL"], var.notification_severity)
    error_message = "Notification severity must be one of: LOW, MEDIUM, HIGH, CRITICAL."
  }
}

#----------------------------------------
# SSL/TLS Configuration
#----------------------------------------
variable "enable_tls" {
  description = "Enable TLS/SSL for connections to ElastiCache Redis"
  type        = bool
  default     = true
}

variable "import_server_ssl_cert" {
  description = "Import ElastiCache Redis server SSL certificate automatically"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Redis AUTH token for authentication (optional, required if Redis AUTH is enabled)"
  type        = string
  default     = null
  sensitive   = true
}

#----------------------------------------
# Debug Configuration
#----------------------------------------
variable "debug_mode" {
  description = "Enable debug mode to print API responses for troubleshooting"
  type        = bool
  default     = false
}

#----------------------------------------
# Tags
#----------------------------------------
variable "tags" {
  description = "Tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
