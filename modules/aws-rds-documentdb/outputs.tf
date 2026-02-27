#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# RDS DocumentDB VA Config Module Outputs

output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.va_config_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.va_config_lambda.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_security_group_id" {
  description = "ID of the security group used by the Lambda function"
  value       = aws_security_group.lambda_sg.id
}

output "lambda_log_group_name" {
  description = "Name of the CloudWatch Log Group for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "lambda_invocation_status" {
  description = "Status of the Lambda invocation"
  value       = "Invoked via gdp-middleware-helper provider"
}

output "lambda_execution_result_parameter" {
  description = "Lambda execution results can be viewed in CloudWatch Logs"
  value       = "Check CloudWatch Log Group: ${aws_cloudwatch_log_group.lambda_log_group.name}"
}

output "documentdb_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DocumentDB credentials"
  value       = aws_secretsmanager_secret.documentdb_credentials.arn
}

output "documentdb_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing DocumentDB credentials"
  value       = aws_secretsmanager_secret.documentdb_credentials.name
}

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = var.sqlguard_username
}

output "sqlguard_password" {
  description = "Password for the sqlguard user"
  value       = var.sqlguard_password
  sensitive   = true
}