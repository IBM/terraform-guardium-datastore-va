# AWS Aurora MySQL VA Configuration Module

This Terraform module configures Vulnerability Assessment (VA) for AWS Aurora MySQL clusters by creating and executing a Lambda function that sets up the necessary database users and permissions.

## Features

- Creates a Lambda function to configure VA on Aurora MySQL
- Sets up AWS Secrets Manager to securely store database credentials
- Configures VPC networking for Lambda to access the Aurora MySQL cluster
- Creates necessary IAM roles and policies
- Establishes security group rules for secure communication

## Prerequisites

- An existing Aurora MySQL cluster
- VPC and subnets where the Aurora MySQL cluster is deployed
- Security group ID of the Aurora MySQL cluster
- Master database credentials with sufficient privileges to create users

## Usage

```hcl
module "aurora_mysql_va_config" {
  source = "../../modules/aws-aurora-mysql"

  name_prefix = "my-aurora-mysql"

  # Database Connection Details
  db_host     = "aurora-mysql-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
  db_port     = 3306
  db_name     = "mysql"
  db_username = "admin"
  db_password = "your-master-password"

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"

  # Lambda Configuration
  vpc_id               = "vpc-xxxxx"
  subnet_ids           = ["subnet-xxxxx", "subnet-yyyyy"]
  db_security_group_id = "sg-xxxxx"

  # General Configuration
  aws_region = "us-east-1"
  tags = {
    Environment = "production"
    Purpose     = "guardium-va-config"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| gdp-middleware-helper | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| gdp-middleware-helper | >= 1.0.0 |

## Resources Created

- AWS Lambda function for VA configuration
- IAM role and policy for Lambda execution
- AWS Secrets Manager secret for database credentials
- VPC endpoint for Secrets Manager
- Security groups for Lambda and VPC endpoint
- Security group rule to allow Lambda access to Aurora MySQL

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix to use for resource names | `string` | n/a | yes |
| db_host | Hostname or IP address of the Aurora MySQL cluster endpoint | `string` | n/a | yes |
| db_port | Port for the Aurora MySQL cluster | `number` | `3306` | no |
| db_name | Name of the Aurora MySQL database | `string` | n/a | yes |
| db_username | Username for the Aurora MySQL database (must have superuser privileges) | `string` | n/a | yes |
| db_password | Password for the Aurora MySQL database | `string` | n/a | yes |
| sqlguard_username | Username for the Guardium user | `string` | `"sqlguard"` | no |
| sqlguard_password | Password for the sqlguard user | `string` | n/a | yes |
| vpc_id | ID of the VPC where the Lambda function will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where the Lambda function will be created | `list(string)` | n/a | yes |
| db_security_group_id | Security group ID of the Aurora MySQL cluster to allow Lambda access | `string` | n/a | yes |
| aws_region | AWS region where resources will be created | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{"Purpose": "guardium-va-config", "Owner": "your-email@example.com"}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user |
| lambda_function_arn | ARN of the Lambda function created for VA configuration |
| lambda_function_name | Name of the Lambda function created for VA configuration |
| security_group_id | ID of the security group created for the Lambda function |
| va_config_completed | Whether the VA configuration has been completed |
| secrets_manager_secret_arn | ARN of the Secrets Manager secret containing Aurora MySQL credentials |

## Notes

- The Lambda function creates a `sqlguard` user in the Aurora MySQL database with the necessary permissions for vulnerability assessment
- The master database credentials are stored securely in AWS Secrets Manager
- The Lambda function is deployed in the same VPC as the Aurora MySQL cluster for secure communication
- All resources are tagged for easy identification and management

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0