# AWS Neptune Vulnerability Assessment Configuration Module

This Terraform module configures AWS Neptune for Guardium Vulnerability Assessment (VA) by creating and configuring a VA user with appropriate permissions.

## Overview

The module performs the following actions:
1. Creates an AWS Lambda function to configure Neptune for VA
2. Stores Neptune credentials securely in AWS Secrets Manager
3. Creates necessary IAM roles and policies for Lambda execution
4. Sets up VPC networking for secure Lambda execution
5. Configures a VA user (sqlguard) in Neptune with required permissions

## Prerequisites

- AWS Neptune cluster already deployed
- VPC and subnets configured
- Appropriate AWS credentials with permissions to create Lambda functions, IAM roles, and Secrets Manager secrets
- The `gdp-middleware-helper` Terraform provider installed

## Usage

```hcl
module "neptune_va_config" {
  source = "../../modules/aws-neptune"

  name_prefix = "my-neptune-va"

  # Neptune Connection Details
  neptune_cluster_endpoint    = "my-neptune-cluster.cluster-xxxxx.us-east-1.neptune.amazonaws.com"
  neptune_cluster_port        = 8182
  neptune_cluster_identifier  = "my-neptune-cluster"
  db_username                 = "admin"
  db_password                 = "your-admin-password"

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"

  # Network Configuration
  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]

  # General Configuration
  aws_region = "us-east-1"
  tags = {
    Environment = "production"
    Purpose     = "guardium-va"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| neptune_cluster_endpoint | Endpoint of the Neptune cluster | `string` | n/a | yes |
| neptune_cluster_port | Port for the Neptune cluster | `number` | `8182` | no |
| neptune_cluster_identifier | Identifier of the Neptune cluster | `string` | n/a | yes |
| db_username | Username for the Neptune database | `string` | n/a | yes |
| db_password | Password for the Neptune database | `string` | n/a | yes |
| sqlguard_username | Username for the Guardium VA user | `string` | `"sqlguard"` | no |
| sqlguard_password | Password for the sqlguard user | `string` | n/a | yes |
| vpc_id | ID of the VPC where Lambda will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for Lambda | `list(string)` | n/a | yes |
| aws_region | AWS region where resources will be created | `string` | n/a | yes |
| name_prefix | Prefix to use for resource names | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_name | Name of the Lambda function used for VA configuration |
| lambda_function_arn | ARN of the Lambda function |
| secret_arn | ARN of the Secrets Manager secret |
| secret_name | Name of the Secrets Manager secret |
| lambda_security_group_id | ID of the Lambda security group |
| vpc_endpoint_id | ID of the VPC endpoint for Secrets Manager |

## Notes

- The Lambda function requires network access to the Neptune cluster
- Ensure the Lambda security group can communicate with Neptune
- The VA user (sqlguard) is created with read-only permissions for vulnerability assessment
- Neptune uses Gremlin/SPARQL query languages, not SQL

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0