# Oracle VA Config Module - Main Configuration

# Get AWS account ID automatically if not provided
data "aws_caller_identity" "current" {}

locals {
  # Use provided AWS account ID or get it automatically
  aws_account_id = data.aws_caller_identity.current.account_id
  # Secret names using the name_prefix for consistency
  secret_name          = "${var.name_prefix}-oracle-va-password"
  lambda_function_archive = "${path.module}/files/lambda_function.zip"
  zip_hash             = fileexists(local.lambda_function_archive) ? filesha256(local.lambda_function_archive) : "placeholder"
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_prefix}-oracle-va-config-lambda-role"

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

resource "aws_secretsmanager_secret" "oracle_credentials" {
  name                           = local.secret_name
  description                    = "Secret for Oracle credentials ${var.db_service_name}"
  recovery_window_in_days        = 0 # Force immediate deletion instead of scheduled deletion
  force_overwrite_replica_secret = true
  tags                           = var.tags
}


resource "aws_secretsmanager_secret_version" "oracle_credentials_version" {
  secret_id = aws_secretsmanager_secret.oracle_credentials.id
  secret_string = jsonencode({
    username          = var.db_username
    password          = var.db_password
    host              = var.db_host
    port              = var.db_port
    service_name      = var.db_service_name
    sqlguard_username = var.sqlguard_username
    sqlguard_password = var.sqlguard_password
  })
}

# Create IAM policy for Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}-oracle-va-config-lambda-policy"
  description = "Policy for Oracle VA configuration Lambda function"

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
          aws_secretsmanager_secret.oracle_credentials.arn,
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
  name        = "${var.name_prefix}-oracle-va-config-lambda-sg"
  description = "Security group for Oracle VA configuration Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Add ingress rule to Oracle RDS security group to allow Lambda access
resource "aws_security_group_rule" "lambda_to_oracle" {
  count = var.oracle_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = var.oracle_security_group_id
  description              = "Allow Lambda to connect to Oracle RDS"
}

# Create Lambda function for VA configuration
resource "aws_lambda_function" "va_config_lambda" {
  function_name = "${var.name_prefix}-oracle-va-config"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512 # Oracle client libraries require more memory

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      SECRETS_MANAGER_SECRET_ID = aws_secretsmanager_secret.oracle_credentials.id
      SECRETS_REGION            = var.aws_region
      DB_TYPE                   = "oracle"
    }
  }

  # Lambda function code with dependencies packaged
  filename         = local.lambda_function_archive
  source_code_hash = local.zip_hash

  tags = var.tags

}




# Invoke Lambda function to configure VA using gdp-middleware-helper provider
# The Lambda function gets its input from environment variables that we've set above
resource "gdp-middleware-helper_execute_aws_lambda_function" "invoke_lambda" {
  function_name = aws_lambda_function.va_config_lambda.function_name
  region        = var.aws_region

  # This variable is not used by the provider, but it will be used as a trigger when the lambda changes
  source_code_hash = local.zip_hash

  depends_on = [
    aws_lambda_function.va_config_lambda,
    aws_vpc_endpoint.secretsmanager
  ]
}