# AWS Oracle with VA Example - Outputs

output "sqlguard_username" {
  description = "Username for the Guardium VA user"
  value       = module.oracle_va_config.sqlguard_username
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function created for VA configuration"
  value       = module.oracle_va_config.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function created for VA configuration"
  value       = module.oracle_va_config.lambda_function_name
}

output "security_group_id" {
  description = "ID of the security group created for the Lambda function"
  value       = module.oracle_va_config.security_group_id
}

output "va_config_completed" {
  description = "Whether the VA configuration has been completed"
  value       = module.oracle_va_config.va_config_completed
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Oracle credentials"
  value       = module.oracle_va_config.secrets_manager_secret_arn
}

output "gdmmonitor_role_created" {
  description = "Confirmation message about gdmmonitor role creation"
  value       = module.oracle_va_config.gdmmonitor_role_created
}

output "datasource_name" {
  description = "Name of the datasource registered in Guardium"
  value       = var.datasource_name
}

output "gdp_connection_status" {
  description = "Status of the Guardium Data Protection connection"
  value       = var.enable_vulnerability_assessment ? "Connected" : "Not Connected"
}