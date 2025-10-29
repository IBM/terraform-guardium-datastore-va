# Redshift VA Config Module Outputs

output "sqlguard_username" {
  description = "Username for the Guardium user"
  value       = var.sqlguard_username
}

output "sqlguard_password" {
  description = "Password for the sqlguard user"
  value       = var.sqlguard_password
  sensitive   = true
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
  description = "ID of the security group created for the Lambda function (if VPC is used)"
  value       = var.vpc_id
}

output "va_config_completed" {
  description = "Whether the VA configuration has been completed"
  value       = gdp-middleware-helper_execute_aws_lambda_function.invoke_lambda.id != null
}

output "redshift_secret_arn" {
  description = "ARN of the Redshift password secret"
  value       = aws_secretsmanager_secret.redshift_password.arn
}

output "sqlguard_secret_arn" {
  description = "ARN of the sqlguard password secret"
  value       = aws_secretsmanager_secret.sqlguard_password.arn
}
