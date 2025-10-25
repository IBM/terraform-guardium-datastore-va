# AWS DynamoDB Vulnerability Assessment Configuration Module - Variables

#----------------------------------------
# IAM Configuration Variables
#----------------------------------------
variable "iam_role_name" {
  description = "Name of the IAM role for Guardium vulnerability assessment"
  type        = string
  default     = "guardium-dynamodb-va-role"
}

variable "iam_policy_name" {
  description = "Name of the IAM policy for Guardium vulnerability assessment"
  type        = string
  default     = "guardium-dynamodb-va-policy"
}

variable "iam_role_description" {
  description = "Description of the IAM role for Guardium vulnerability assessment"
  type        = string
  default     = "IAM role for Guardium vulnerability assessment of DynamoDB"
}

#----------------------------------------
# Tags
#----------------------------------------
variable "tags" {
  description = "Tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}
