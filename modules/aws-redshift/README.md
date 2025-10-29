# AWS Redshift Vulnerability Assessment Configuration Module

This module configures an AWS Redshift cluster for Guardium Vulnerability Assessment (VA). It creates the necessary user accounts and permissions required for Guardium to perform vulnerability assessments on the Redshift cluster.

## Features

- Creates a `sqlguard` user (or custom username) for Guardium VA
- Creates a `gdmmonitor` group and adds the VA user to it
- Grants necessary permissions for VA to access system tables and user data
- Uses AWS Lambda to execute SQL commands, eliminating the need for local PostgreSQL client installation
- Supports both public and private Redshift clusters (VPC configuration is optional)

## Usage

```hcl
# For publicly accessible Redshift clusters
module "datastore-va_aws-redshift" {
  source = "IBM/datastore-va/guardium//modules/aws-redshift"
  
  # General Configuration
  name_prefix = "guardium"
  aws_region  = "us-east-1"
  
  # Redshift Connection Details
  redshift_host     = "your-redshift-cluster.region.redshift.amazonaws.com"
  redshift_port     = 5439
  redshift_database = "dev"
  redshift_username = "admin"
  redshift_password = "your-password"
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"
  
  # Tags
  tags = {
    Environment = "dev"
    Owner       = "security-team"
  }
}

# For Redshift clusters in a private VPC
module "datastore-va_aws-redshift" {
  source = "IBM/datastore-va/guardium//modules/aws-redshift"
  
  # General Configuration
  name_prefix = "guardium"
  aws_region  = "us-east-1"
  
  # Redshift Connection Details
  redshift_host     = "your-redshift-cluster.region.redshift.amazonaws.com"
  redshift_port     = 5439
  redshift_database = "dev"
  redshift_username = "admin"
  redshift_password = "your-password"
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"
  
  # Network Configuration for Lambda (required for private Redshift)
  vpc_id    = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  
  # Tags
  tags = {
    Environment = "dev"
    Owner       = "security-team"
  }
}
```

## Requirements

- AWS provider >= 5.0
- Terraform >= 1.0.0
- For private Redshift clusters: VPC and subnet with internet access (for Lambda to connect to Redshift)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | "guardium" | no |
| redshift_host | Hostname or IP address of the Redshift cluster | string | n/a | yes |
| redshift_port | Port for the Redshift cluster | number | 5439 | no |
| redshift_database | Name of the Redshift database | string | n/a | yes |
| redshift_username | Username for the Redshift database (must have superuser privileges) | string | n/a | yes |
| redshift_password | Password for the Redshift database | string | n/a | yes |
| sqlguard_username | Username for the Guardium user | string | "sqlguard" | no |
| sqlguard_password | Password for the sqlguard user | string | n/a | yes |
| vpc_id | ID of the VPC where the Lambda function will be created (optional, only needed if Redshift is in a private VPC) | string | "" | no |
| subnet_id | ID of the subnet where the Lambda function will be created (optional, only needed if Redshift is in a private VPC) | string | "" | no |
| aws_region | AWS region where resources will be created | string | "us-east-1" | no |
| tags | Tags to apply to all resources | map(string) | `{ Purpose = "guardium-va-config", Owner = "your-email@example.com" }` | no |

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user |
| sqlguard_password | Password for the sqlguard user |
| lambda_function_arn | ARN of the Lambda function created for VA configuration |
| lambda_function_name | Name of the Lambda function created for VA configuration |
| security_group_id | ID of the security group created for the Lambda function |
| va_config_completed | Whether the VA configuration has been completed |

