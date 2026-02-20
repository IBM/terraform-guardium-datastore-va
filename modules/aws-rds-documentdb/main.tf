#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# DocumentDB VA Config Module - Main Configuration

# Get AWS account ID automatically if not provided
data "aws_caller_identity" "current" {}

locals {
  # Use provided AWS account ID or get it automatically
  aws_account_id = data.aws_caller_identity.current.account_id
  # Secret names using the name_prefix for consistency
  secret_name = "${var.name_prefix}-documentdb-va-password"
  zip_file    = "${path.module}/files/lambda_function.zip"
  zip_hash    = filesha256(local.zip_file)
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-documentdb-va-config-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_secretsmanager_secret" "documentdb_credentials" {
  name                    = local.secret_name
  description             = "Secret for DocumentDB credentials ${var.db_host}"
  recovery_window_in_days = 0
  tags                    = var.tags
}


resource "aws_secretsmanager_secret_version" "documentdb_credentials_version" {
  secret_id = aws_secretsmanager_secret.documentdb_credentials.id
  secret_string = jsonencode({
    username = var.sqlguard_username # GDP expects VA user credentials at top level
    password = var.sqlguard_password
    endpoint = var.db_host
    port     = var.db_port
    database = var.db_name
    # Store admin credentials for reference
    admin_username = var.db_username
    admin_password = var.db_password
  })
}

# Create IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-documentdb-va-config-lambda-policy"
  description = "Policy for DocumentDB VA configuration Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.documentdb_credentials.arn,
        ]
      }
    ]
  })
}

# Security group for the Secrets Manager VPC endpoint
resource "aws_security_group" "secretsmanager_endpoint_sg" {
  name        = "${var.name_prefix}-secretsmanager-endpoint-sg"
  description = "Security group for Secrets Manager VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description     = "Allow HTTPS from Lambda security group"
  }

  tags = var.tags
}

# VPC Endpoint for Secrets Manager to allow Lambda to access it from private VPC
# Always create a new VPC endpoint for this deployment
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.secretsmanager_endpoint_sg.id]
  private_dns_enabled = true # Enable private DNS so Lambda can resolve secretsmanager.us-east-1.amazonaws.com

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-secretsmanager-endpoint"
    }
  )
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.name_prefix}-documentdb-va-config-lambda-sg"
  description = "Security group for DocumentDB VA configuration Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = false
  }
}

# Add ingress rule to DocumentDB security group to allow Lambda access
resource "aws_security_group_rule" "documentdb_allow_lambda" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = var.db_security_group_id
  description              = "Allow Lambda function to connect to DocumentDB for VA configuration"
}

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.name_prefix}-documentdb-va-config"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Create Lambda function for VA configuration
resource "aws_lambda_function" "va_config_lambda" {
  function_name = "${var.name_prefix}-documentdb-va-config"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      SECRETS_MANAGER_SECRET_ID = aws_secretsmanager_secret.documentdb_credentials.id
      SECRETS_REGION            = var.aws_region
      LOG_LEVEL                 = var.lambda_log_level
    }
  }

  # Lambda function code with dependencies packaged
  filename         = local.zip_file
  source_code_hash = local.zip_hash

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

# CloudWatch Metric Filter for successful executions
resource "aws_cloudwatch_log_metric_filter" "lambda_success_metric" {
  name           = "${var.name_prefix}-documentdb-lambda-success"
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name
  pattern        = "\"One-time operation completed successfully\""

  metric_transformation {
    name      = "DocumentDBLambdaSuccess"
    namespace = "CustomMetrics"
    value     = "1"
  }
}

# SSM Parameter removed due to IAM permission requirements
# Users would need ssm:DeleteParameter permission which may not be available
# Lambda execution results can be viewed in CloudWatch Logs instead


# Invoke Lambda function to configure VA using gdp-middleware-helper provider
# The Lambda function gets its credentials from AWS Secrets Manager
# (DB admin credentials and sqlguard VA user credentials)
resource "gdp-middleware-helper_execute_aws_lambda_function" "invoke_lambda" {
  function_name = aws_lambda_function.va_config_lambda.function_name
  region        = var.aws_region

  # This variable is not used by the provider, but it will be used as a trigger when the lambda changes
  source_code_hash = local.zip_hash

  depends_on = [
    aws_lambda_function.va_config_lambda,
  ]
}
