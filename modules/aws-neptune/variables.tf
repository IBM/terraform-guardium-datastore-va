#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS Neptune VA Config Module Variables

variable "neptune_cluster_endpoint" {
  description = "Endpoint of the Neptune cluster"
  type        = string
}

variable "neptune_cluster_port" {
  description = "Port for the Neptune cluster"
  type        = number
  default     = 8182
}

variable "neptune_cluster_identifier" {
  description = "Identifier of the Neptune cluster"
  type        = string
}

variable "neptune_security_group_id" {
  description = "Security group ID of the Neptune cluster (optional - if provided, will add ingress rule to allow Lambda access)"
  type        = string
  default     = ""
}

variable "neptune_port" {
  description = "Port for Neptune cluster connectivity"
  type        = number
  default     = 8182
}

variable "db_username" {
  description = "Username for the Neptune database (must have appropriate privileges)"
  type        = string
}

variable "db_password" {
  description = "Password for the Neptune database"
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
  description = "List of IDs of the subnets where the Lambda function will be created"
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

variable "use_iam_auth" {
  description = "Use IAM authentication for Neptune (recommended). Set to false only if using database authentication."
  type        = bool
  default     = true
}