#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# Oracle VA Config Module Outputs

output "sqlguard_username" {
  description = "Username for the Guardium user"
  value       = var.sqlguard_username
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function created for VA configuration"
  value       = aws_lambda_function.va_config_lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function created for VA configuration"
  value       = aws_lambda_function.va_config_lambda.function_name
}

output "security_group_id" {
  description = "ID of the security group created for the Lambda function"
  value       = aws_security_group.lambda_sg.id
}

output "va_config_completed" {
  description = "Whether the VA configuration has been completed"
  value       = true
  depends_on  = [gdp-middleware-helper_execute_aws_lambda_function.invoke_lambda]
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Oracle credentials"
  value       = aws_secretsmanager_secret.oracle_credentials.arn
}

output "gdmmonitor_role_created" {
  description = "Indicates that the gdmmonitor role has been created in Oracle"
  value       = "Role created - grant to sqlguard user using: GRANT gdmmonitor TO ${var.sqlguard_username}"
  depends_on  = [gdp-middleware-helper_execute_aws_lambda_function.invoke_lambda]
}