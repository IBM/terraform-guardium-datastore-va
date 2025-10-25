# AWS DynamoDB with Vulnerability Assessment Example - Outputs

#----------------------------------------
# IAM Configuration Outputs
#----------------------------------------
output "va_iam_role_arn" {
  description = "ARN of the IAM role used for vulnerability assessment"
  value       = module.dynamodb_va.iam_role_arn
}

output "va_iam_policy_arn" {
  description = "ARN of the IAM policy for vulnerability assessment"
  value       = module.dynamodb_va.iam_policy_arn
}

#----------------------------------------
# Guardium Connection Outputs
#----------------------------------------
output "datasource_name" {
  description = "Name of the registered datasource in Guardium"
  value       = var.dynamodb_datasource_name
}

output "datasource_type" {
  description = "Type of the registered datasource in Guardium"
  value       = "Amazon DynamoDB"
}

output "datasource_hostname" {
  description = "Hostname of the registered datasource in Guardium"
  value       = "dynamodb.${var.aws_region}.amazonaws.com"
}

#----------------------------------------
# Vulnerability Assessment Outputs
#----------------------------------------
output "va_enabled" {
  description = "Whether vulnerability assessment is enabled"
  value       = var.enable_vulnerability_assessment
}

output "assessment_schedule" {
  description = "Schedule for vulnerability assessments"
  value       = var.assessment_schedule
}

output "assessment_day" {
  description = "Day for vulnerability assessments"
  value       = var.assessment_day
}

output "assessment_time" {
  description = "Time for vulnerability assessments"
  value       = var.assessment_time
}

output "gdp_server" {
  description = "Hostname of the Guardium Data Protection server"
  value       = module.dynamodb_gdp_connection.guardium_server
}

#----------------------------------------
# Notification Outputs
#----------------------------------------
output "notifications_enabled" {
  description = "Whether notifications are enabled"
  value       = var.enable_notifications
}

output "notification_emails" {
  description = "Email addresses for notifications"
  value       = var.notification_emails
}

output "notification_severity" {
  description = "Minimum severity level for notifications"
  value       = var.notification_severity
}

#----------------------------------------
# AWS Secrets Manager Configuration Outputs
#----------------------------------------
output "aws_secrets_manager_name" {
  description = "Name of the AWS Secrets Manager configuration in Guardium"
  value       = var.aws_secrets_manager_name
}

output "aws_secrets_manager_region" {
  description = "AWS region where the Secrets Manager secret is stored"
  value       = var.aws_secrets_manager_region
}

output "aws_secrets_manager_secret" {
  description = "Name of the secret in AWS Secrets Manager containing AWS credentials"
  value       = var.aws_secrets_manager_secret != null ? var.aws_secrets_manager_secret : local.secret_name
}

#----------------------------------------
# Debug Configuration Outputs
#----------------------------------------
output "debug_mode_enabled" {
  description = "Whether debug mode is enabled for API responses"
  value       = var.debug_mode
}