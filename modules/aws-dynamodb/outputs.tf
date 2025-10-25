# AWS DynamoDB Vulnerability Assessment Configuration Module - Outputs

#----------------------------------------
# IAM Role Outputs
#----------------------------------------
output "iam_role_arn" {
  description = "ARN of the IAM role for Guardium vulnerability assessment"
  value       = aws_iam_role.guardium_va_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for Guardium vulnerability assessment"
  value       = aws_iam_role.guardium_va_role.name
}

output "iam_role_id" {
  description = "ID of the IAM role for Guardium vulnerability assessment"
  value       = aws_iam_role.guardium_va_role.id
}

#----------------------------------------
# IAM Policy Outputs
#----------------------------------------
output "iam_policy_arn" {
  description = "ARN of the IAM policy for Guardium vulnerability assessment"
  value       = aws_iam_policy.guardium_va_policy.arn
}

output "iam_policy_name" {
  description = "Name of the IAM policy for Guardium vulnerability assessment"
  value       = aws_iam_policy.guardium_va_policy.name
}

output "iam_policy_id" {
  description = "ID of the IAM policy for Guardium vulnerability assessment"
  value       = aws_iam_policy.guardium_va_policy.id
}

