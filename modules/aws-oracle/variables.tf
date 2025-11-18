#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# Oracle VA Config Module Variables

variable "db_host" {
  description = "Hostname or IP address of the Oracle database"
  type        = string
}

variable "db_port" {
  description = "Port for the Oracle database"
  type        = number
  default     = 1521
}

variable "db_service_name" {
  description = "Service name of the Oracle database (e.g., ORCL, ORCLPDB1)"
  type        = string
}

variable "db_username" {
  description = "Username for the Oracle database (must have DBA privileges or ADMIN for Autonomous)"
  type        = string
}

variable "db_password" {
  description = "Password for the Oracle database"
  type        = string
  sensitive   = true
}

variable "sqlguard_username" {
  description = "Username for the Guardium VA user (will be created and granted gdmmonitor role)"
  type        = string
  default     = "sqlguard"
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "ID of the VPC where the Lambda function will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Lambda function will be created"
  type        = list(string)
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

variable "oracle_security_group_id" {
  description = "Security group ID of the Oracle RDS instance (optional - will add Lambda access if provided)"
  type        = string
  default     = ""
}