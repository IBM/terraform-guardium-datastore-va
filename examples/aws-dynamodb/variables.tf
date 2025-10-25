# AWS DynamoDB with Vulnerability Assessment Example - Variables

#----------------------------------------
# AWS Configuration
#----------------------------------------
variable "aws_region" {
  description = "AWS region where DynamoDB is deployed"
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
# AWS Secrets Manager Configuration for DynamoDB
#----------------------------------------
variable "aws_secrets_manager_name" {
  description = "Name of the AWS Secrets Manager configuration in Guardium"
  type        = string
  default     = "guardium-aws"
}

variable "aws_secrets_manager_region" {
  description = "AWS region where the Secrets Manager secret is stored"
  type        = string
  default     = "us-east-1"
}

variable "aws_secrets_manager_secret" {
  description = "Name of the secret in AWS Secrets Manager containing AWS credentials"
  type        = string
}

variable "dynamodb_datasource_name" {
  description = "Name to register the DynamoDB datasource in Guardium"
  type        = string
  default     = "aws-dynamodb-va-example"
}

variable "dynamodb_description" {
  description = "Description for the DynamoDB datasource in Guardium"
  type        = string
  default     = "AWS DynamoDB with Vulnerability Assessment"
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
  description = "Whether to enable vulnerability assessment for DynamoDB"
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

#----------------------------------------
# Debug Configuration
#----------------------------------------
variable "debug_mode" {
  description = "Enable debug mode to print API responses for troubleshooting"
  type        = bool
  default     = false
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
# Tags
#----------------------------------------
variable "tags" {
  description = "Tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}