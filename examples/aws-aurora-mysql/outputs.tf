#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS Aurora MySQL with VA Example - Outputs

output "lambda_function_arn" {
  description = "ARN of the Lambda function created for VA configuration"
  value       = module.aurora_mysql_va_config.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function created for VA configuration"
  value       = module.aurora_mysql_va_config.lambda_function_name
}

output "security_group_id" {
  description = "ID of the security group created for the Lambda function"
  value       = module.aurora_mysql_va_config.security_group_id
}

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = module.aurora_mysql_va_config.sqlguard_username
}

output "va_config_completed" {
  description = "Whether the VA configuration has been completed"
  value       = module.aurora_mysql_va_config.va_config_completed
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Aurora MySQL credentials"
  value       = module.aurora_mysql_va_config.secrets_manager_secret_arn
}