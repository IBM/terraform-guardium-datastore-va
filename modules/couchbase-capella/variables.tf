#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Couchbase Capella VA Config Module Variables

variable "cluster_endpoint" {
  description = "Couchbase Capella cluster endpoint (e.g., cb.abc123.cloud.couchbase.com)"
  type        = string
  validation {
    condition     = length(var.cluster_endpoint) > 0
    error_message = "Cluster endpoint cannot be empty."
  }
}

variable "bucket_name" {
  description = "Couchbase bucket name for VA assessment"
  type        = string
  validation {
    condition     = length(var.bucket_name) > 0
    error_message = "Bucket name cannot be empty."
  }
}

variable "admin_username" {
  description = "Admin username for Couchbase Capella (must have appropriate privileges to create users)"
  type        = string
}

variable "admin_password" {
  description = "Admin password for Couchbase Capella"
  type        = string
  sensitive   = true
}

variable "connection_string" {
  description = "Full Couchbase connection string (e.g., couchbases://cb.abc123.cloud.couchbase.com)"
  type        = string
  sensitive   = true
}

variable "rest_api_endpoint" {
  description = "Couchbase REST API endpoint for Guardium (e.g., https://cb.abc123.cloud.couchbase.com:18091)"
  type        = string
}

variable "cluster_port" {
  description = "Port for Couchbase Capella cluster"
  type        = number
  default     = 18091
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user"
  type        = string
  sensitive   = true
}

variable "sqlguard_username" {
  description = "Username for the Guardium VA user"
  type        = string
  default     = "sqlguard"
}

variable "vpc_id" {
  description = "ID of the VPC where the Lambda function will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of IDs of the subnets where the Lambda function will be created (must have internet access via NAT Gateway for Couchbase Capella)"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

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

variable "guardium_hostname" {
  description = "Guardium hostname or IP address (optional, for reference)"
  type        = string
  default     = ""
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.lambda_timeout >= 30 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 30 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}
