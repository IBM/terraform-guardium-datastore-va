#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Couchbase Capella VA Config Module - Main Configuration

# Get AWS account ID automatically if not provided
data "aws_caller_identity" "current" {}

locals {
  # Use provided AWS account ID or get it automatically
  aws_account_id = data.aws_caller_identity.current.account_id
  # Secret names using the name_prefix for consistency
  secret_name = "${var.name_prefix}-couchbase-capella-va-credentials"
  zip_file    = "${path.module}/files/lambda_function.zip"
  zip_hash    = filesha256(local.zip_file)
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-couchbase-capella-va-config-lambda-role"

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

resource "aws_secretsmanager_secret" "couchbase_credentials" {
  name                           = local.secret_name
  description                    = "Couchbase Capella credentials for Guardium VA - Bucket: ${var.bucket_name}"
  recovery_window_in_days        = 0 # Force immediate deletion instead of scheduled deletion
  force_overwrite_replica_secret = true
  tags                           = var.tags
}


resource "aws_secretsmanager_secret_version" "couchbase_credentials_version" {
  secret_id = aws_secretsmanager_secret.couchbase_credentials.id
  secret_string = jsonencode({
    username          = var.admin_username
    password          = var.admin_password
    cluster_endpoint  = var.cluster_endpoint
    rest_api_endpoint = var.rest_api_endpoint
    port              = var.cluster_port
    bucket_name       = var.bucket_name
    connection_string = var.connection_string
    tls_enabled       = true
    sqlguard_username = var.sqlguard_username
    sqlguard_password = var.sqlguard_password
    guardium_hostname = var.guardium_hostname
  })

  depends_on = [aws_secretsmanager_secret.couchbase_credentials]

  lifecycle {
    create_before_destroy = true
  }
}

# Create IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-couchbase-capella-va-config-lambda-policy"
  description = "Policy for Couchbase Capella VA configuration Lambda function"

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
          aws_secretsmanager_secret.couchbase_credentials.arn,
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
# private_dns_enabled is set to true so Lambda can use the standard AWS endpoint URL
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.secretsmanager_endpoint_sg.id]
  private_dns_enabled = true

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.name_prefix}-couchbase-capella-va-config-lambda-sg"
  description = "Security group for Couchbase Capella VA configuration Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic (required for Couchbase Capella cloud service and internet access)"
  }

  tags = var.tags
}

# Create Lambda function for VA configuration
resource "aws_lambda_function" "va_config_lambda" {
  function_name                  = "${var.name_prefix}-couchbase-capella-va-config"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.handler"
  runtime                        = "python3.11"
  timeout                        = var.lambda_timeout
  memory_size                    = var.lambda_memory_size
  reserved_concurrent_executions = 1

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      SECRETS_MANAGER_SECRET_ID = aws_secretsmanager_secret.couchbase_credentials.id
      SECRETS_REGION            = var.aws_region
      DATASOURCE_TYPE           = "Couchbase Capella"
    }
  }

  # Lambda function code with dependencies packaged
  filename         = local.zip_file
  source_code_hash = local.zip_hash

  tags = var.tags

}




# Trigger for Lambda invocation idempotency
resource "null_resource" "lambda_invocation_trigger" {
  triggers = {
    lambda_code_hash = local.zip_hash
    secret_version   = aws_secretsmanager_secret_version.couchbase_credentials_version.version_id
  }
}

# Invoke Lambda function to configure VA using gdp-middleware-helper provider
# The Lambda function gets its input from environment variables that we've set above
resource "gdp-middleware-helper_execute_aws_lambda_function" "invoke_lambda" {
  function_name = aws_lambda_function.va_config_lambda.function_name
  region        = var.aws_region

  # This variable is not used by the provider, but it will be used as a trigger when the lambda changes
  source_code_hash = local.zip_hash

  lifecycle {
    replace_triggered_by = [null_resource.lambda_invocation_trigger]
  }

  depends_on = [
    aws_lambda_function.va_config_lambda,
    aws_vpc_endpoint.secretsmanager
  ]
}
