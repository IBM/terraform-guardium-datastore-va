#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# SQL Server VA Config Module - Main Configuration

# Get AWS account ID automatically if not provided
data "aws_caller_identity" "current" {}

locals {
  # Use provided AWS account ID or get it automatically
  aws_account_id = data.aws_caller_identity.current.account_id
  # Secret name using the name_prefix for consistency
  secret_name = "${var.name_prefix}-mssql-rds-va-credentials"
}

#------------------------------------------------------------------------------
# AWS Secrets Manager - Store rdsadmin credentials securely
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "mssql_credentials" {
  name        = local.secret_name
  description = "RDS SQL Server credentials for ${var.db_host}"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "mssql_credentials_version" {
  secret_id = aws_secretsmanager_secret.mssql_credentials.id
  secret_string = jsonencode({
    username = var.db_username  
    password = var.db_password
    endpoint = var.db_host
    port     = var.db_port
  })
}