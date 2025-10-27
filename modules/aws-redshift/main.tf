# Redshift VA Config Module - Main Configuration

# Get AWS account ID automatically if not provided
data "aws_caller_identity" "current" {}

locals {
  # Use provided AWS account ID or get it automatically
  aws_account_id = data.aws_caller_identity.current.account_id
  
  # Secret names using the name_prefix for consistency
  redshift_secret_name = "${var.name_prefix}-redshift-password"
  sqlguard_secret_name = "${var.name_prefix}-sqlguard-password"
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-redshift-va-config-lambda-role"

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

# Create AWS Secrets Manager secrets for passwords
resource "aws_secretsmanager_secret" "redshift_password" {
  name                    = local.redshift_secret_name
  description             = "Password for Redshift admin user"
  recovery_window_in_days = 0  # Force immediate deletion instead of scheduled deletion
  force_overwrite_replica_secret = true
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "redshift_password" {
  secret_id     = aws_secretsmanager_secret.redshift_password.id
  secret_string = var.redshift_password
}

resource "aws_secretsmanager_secret" "sqlguard_password" {
  name                    = local.sqlguard_secret_name
  description             = "Password for Redshift sqlguard user"
  recovery_window_in_days = 0  # Force immediate deletion instead of scheduled deletion
  force_overwrite_replica_secret = true
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "sqlguard_password" {
  secret_id     = aws_secretsmanager_secret.sqlguard_password.id
  secret_string = var.sqlguard_password
}

# Create IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-redshift-va-config-lambda-policy"
  description = "Policy for Redshift VA configuration Lambda function"

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
        Effect   = "Allow"
        Resource = [
          aws_secretsmanager_secret.redshift_password.arn,
          aws_secretsmanager_secret.sqlguard_password.arn
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Create security group for Lambda function (only if VPC is specified)
resource "aws_security_group" "lambda_sg" {
  count = var.vpc_id != "" && var.subnet_id != "" ? 1 : 0
  
  name        = "${var.name_prefix}-redshift-va-config-lambda-sg"
  description = "Security group for Redshift VA configuration Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_egress_cidr_blocks
  }

  # Allow outbound access to Redshift
  egress {
    from_port   = var.redshift_port
    to_port     = var.redshift_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_egress_cidr_blocks
  }

  tags = var.tags
}

# Create Lambda function for VA configuration
resource "aws_lambda_function" "va_config_lambda" {
  function_name = "${var.name_prefix}-redshift-va-config"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 256

  # VPC configuration is optional - only apply if vpc_id and subnet_id are provided
  dynamic "vpc_config" {
    for_each = var.vpc_id != "" && var.subnet_id != "" ? [1] : []
    content {
      subnet_ids         = [var.subnet_id]
      security_group_ids = [aws_security_group.lambda_sg[0].id]
    }
  }

  environment {
    variables = {
      REDSHIFT_HOST           = var.redshift_host
      REDSHIFT_PORT           = var.redshift_port
      REDSHIFT_DATABASE       = var.redshift_database
      REDSHIFT_USERNAME       = var.redshift_username
      REDSHIFT_SECRET_NAME    = aws_secretsmanager_secret.redshift_password.name
      SQLGUARD_USERNAME       = var.sqlguard_username
      SQLGUARD_SECRET_NAME    = aws_secretsmanager_secret.sqlguard_password.name
      SECRETS_REGION          = var.aws_region
    }
  }

  # Lambda function code with dependencies packaged
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = var.tags
  
  depends_on = [data.archive_file.lambda_zip]
}

# Create zip file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/files/lambda_function.zip"
  source_dir  = "${path.module}/files/lambda_package"
}



# Invoke Lambda function to configure VA using gdp-middleware-helper provider
# The Lambda function gets its input from environment variables that we've set above
# (REDSHIFT_PASSWORD and SQLGUARD_PASSWORD)
resource "gdp-middleware-helper_execute_aws_lambda_function" "invoke_lambda" {
  function_name = aws_lambda_function.va_config_lambda.function_name
  region        = var.aws_region
  
  # This variable is not used by the provider, but it will be used as a trigger when the lambda changes
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  depends_on = [
    aws_lambda_function.va_config_lambda,
  ]
}