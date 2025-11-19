#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# Aurora PostgreSQL VA Config Module Variables

variable "db_host" {
  description = "Hostname or IP address of the Aurora PostgreSQL cluster endpoint"
  type        = string
}

variable "db_port" {
  description = "Port for the Aurora PostgreSQL cluster"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the Aurora PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the Aurora PostgreSQL database (must have superuser privileges)"
  type        = string
}

variable "db_password" {
  description = "Password for the Aurora PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user"
  type        = string
  sensitive   = true
}

variable "sqlguard_username" {
  description = "Username for the Guardium user"
  type        = string
  default     = "sqlguard"
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
  default     = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "db_security_group_id" {
  description = "Security group ID of the Aurora PostgreSQL cluster to allow Lambda access"
  type        = string

}