# AWS DynamoDB Vulnerability Assessment Configuration Module

#----------------------------------------
# IAM Role for Guardium Vulnerability Assessment
#----------------------------------------
resource "aws_iam_role" "guardium_va_role" {
  name        = var.iam_role_name
  description = var.iam_role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "*"  # This will be restricted by external trust relationships in Guardium
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = var.iam_role_name
      Description = "IAM role for Guardium vulnerability assessment of DynamoDB"
      Service     = "Guardium"
      Purpose     = "Vulnerability Assessment"
    }
  )
}

#----------------------------------------
# IAM Policy for DynamoDB Vulnerability Assessment
#----------------------------------------
resource "aws_iam_policy" "guardium_va_policy" {
  name        = var.iam_policy_name
  description = "Policy for Guardium to perform vulnerability assessment on DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # List and describe DynamoDB resources
          "dynamodb:List*",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          
          # Read table metadata
          "dynamodb:DescribeTable",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeGlobalTableSettings",
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeReservedCapacity",
          "dynamodb:DescribeReservedCapacityOfferings",
          
          # Read table configuration
          "dynamodb:GetResourcePolicy",
          "dynamodb:ListTagsOfResource",
          
          # Read backup and restore configuration
          "dynamodb:DescribeBackup",
          "dynamodb:ListBackups",
          
          # Read global tables configuration
          "dynamodb:DescribeGlobalTable",
          "dynamodb:ListGlobalTables",
          
          # Read table streams
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams",
          
          # Read table metrics
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          
          # Read IAM policies related to DynamoDB
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          
          # Read KMS keys used by DynamoDB
          "kms:DescribeKey",
          "kms:ListAliases",
          "kms:ListKeys",
          
          # Read VPC endpoints for DynamoDB
          "ec2:DescribeVpcEndpoints"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = var.iam_policy_name
      Description = "Policy for Guardium vulnerability assessment of DynamoDB"
      Service     = "Guardium"
      Purpose     = "Vulnerability Assessment"
    }
  )
}

#----------------------------------------
# Attach Policy to Role
#----------------------------------------
resource "aws_iam_role_policy_attachment" "guardium_va_policy_attachment" {
  role       = aws_iam_role.guardium_va_role.name
  policy_arn = aws_iam_policy.guardium_va_policy.arn
}