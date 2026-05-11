# AWS ElastiCache Redis Vulnerability Assessment Configuration Module - Variables

#----------------------------------------
# Guardium Connection Configuration
#----------------------------------------
variable "guardium_host" {
  description = "Hostname or IP address of the Guardium Data Protection server"
  type        = string
}

variable "guardium_port" {
  description = "Port for Guardium Data Protection API connection"
  type        = number
  default     = 8443
}

variable "guardium_user" {
  description = "Username for Guardium API authentication"
  type        = string
}

variable "guardium_password" {
  description = "Password for Guardium API authentication"
  type        = string
  sensitive   = true
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

variable "aws_region" {
  description = "AWS region where ElastiCache Redis is deployed"
  type        = string
}

#----------------------------------------

variable "aws_secrets_manager_config_name" {
  description = "Name of the AWS Secrets Manager configuration in Guardium"
  type        = string
}

# Datasource Configuration
#----------------------------------------
variable "datasource_name" {
  description = "Name to register the ElastiCache Redis datasource in Guardium"
  type        = string
}

variable "datasource_description" {
  description = "Description for the ElastiCache Redis datasource in Guardium"
  type        = string
  default     = "AWS ElastiCache Redis with Vulnerability Assessment"
}

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
# Security Configuration
#----------------------------------------
variable "enable_tls" {
  description = "Enable TLS/SSL connection to ElastiCache Redis"
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
# Tags
#----------------------------------------
variable "tags" {
  description = "Tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
