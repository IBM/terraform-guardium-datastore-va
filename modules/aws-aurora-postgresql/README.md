# Aurora PostgreSQL Vulnerability Assessment Configuration Module

This module configures an AWS Aurora PostgreSQL cluster for Guardium Vulnerability Assessment (VA). It creates the necessary users and permissions required for Guardium to perform security assessments and entitlement reports.

## Features

- Creates a `sqlguard` user with the necessary permissions
- Creates a `gdmmonitor` group and adds the `sqlguard` user to it
- Grants the required permissions for Guardium VA to work properly
- Executes the VA configuration script from the Guardium documentation
- Uses AWS Lambda to execute SQL commands within VPC
- Supports Aurora PostgreSQL clusters in private VPCs

## Prerequisites

- Aurora PostgreSQL version 10.x or above
- The user executing the script must have superuser privileges
- The Aurora cluster must be accessible from the Lambda function (VPC configuration required)
- VPC with subnets that have connectivity to the Aurora cluster

## Usage

### Basic Usage

```hcl
module "datastore-va_aws-aurora-postgresql" {
  source = "IBM/datastore-va/guardium//modules/aws-aurora-postgresql"

  name_prefix = "guardium"
  aws_region  = "us-east-1"

  # Aurora PostgreSQL Connection Details
  db_host     = "your-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "postgres"
  db_password = "your-password"

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"

  # Network Configuration for Lambda
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Tags
  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}
```

### Custom sqlguard User

```hcl
module "datastore-va_aws-aurora-postgresql" {
  source = "IBM/datastore-va/guardium//modules/aws-aurora-postgresql"

  name_prefix = "guardium"
  aws_region  = "us-east-1"

  db_host          = "your-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
  db_port          = 5432
  db_name          = "postgres"
  db_username      = "postgres"
  db_password      = "your-password"
  
  sqlguard_username = "custom_guard"
  sqlguard_password = "custom-password"

  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}
```

## Requirements

- AWS provider >= 5.0
- Terraform >= 1.0.0
- gdp-middleware-helper provider >= 1.0.0
- VPC and subnets with connectivity to Aurora cluster

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | n/a | yes |
| db_host | Hostname or IP address of the Aurora PostgreSQL cluster endpoint | string | n/a | yes |
| db_port | Port for the Aurora PostgreSQL cluster | number | 5432 | no |
| db_name | Name of the Aurora PostgreSQL database | string | n/a | yes |
| db_username | Username for the Aurora PostgreSQL database (must have superuser privileges) | string | n/a | yes |
| db_password | Password for the Aurora PostgreSQL database | string | n/a | yes |
| sqlguard_username | Username for the Guardium user | string | "sqlguard" | no |
| sqlguard_password | Password for the sqlguard user | string | n/a | yes |
| vpc_id | ID of the VPC where the Lambda function will be created | string | n/a | yes |
| subnet_ids | List of subnet IDs where the Lambda function will be created | list(string) | n/a | yes |
| aws_region | AWS region where resources will be created | string | n/a | yes |
| tags | Tags to apply to all resources | map(string) | `{ Purpose = "guardium-va-config", Owner = "your-email@example.com" }` | no |

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user |
| lambda_function_arn | ARN of the Lambda function created for VA configuration |
| lambda_function_name | Name of the Lambda function created for VA configuration |
| security_group_id | ID of the security group created for the Lambda function |
| va_config_completed | Whether the VA configuration has been completed |
| secrets_manager_secret_arn | ARN of the Secrets Manager secret containing Aurora PostgreSQL credentials |

## Notes

- The module uses AWS Lambda to execute the VA configuration SQL commands
- All credentials are stored securely in AWS Secrets Manager
- The Lambda function is deployed in the specified VPC to access the Aurora cluster
- A VPC endpoint for Secrets Manager is created to allow Lambda to retrieve credentials
- The module creates the necessary IAM roles and policies for Lambda execution
- The SQL script executed is based on Guardium's official PostgreSQL VA configuration requirements

## Security Considerations

- Ensure the Aurora cluster's security group allows inbound connections from the Lambda security group
- The Lambda function requires network connectivity to both the Aurora cluster and AWS Secrets Manager
- All passwords are marked as sensitive and stored securely in AWS Secrets Manager
- The Secrets Manager secret is configured for immediate deletion (recovery_window_in_days = 0) to facilitate testing

## Aurora-Specific Notes

- This module is designed for Aurora PostgreSQL clusters (both provisioned and serverless v2)
- Use the cluster endpoint (not instance endpoints) for the `db_host` variable
- Aurora PostgreSQL is compatible with standard PostgreSQL, so the same VA configuration applies
- For Aurora Serverless v2, ensure the cluster has sufficient capacity to handle the Lambda connections