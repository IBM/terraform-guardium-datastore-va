# AWS Aurora MySQL with Vulnerability Assessment Example

This example demonstrates how to configure Vulnerability Assessment (VA) for an AWS Aurora MySQL cluster using Terraform.

## Overview

This example:
1. Configures VA on an existing Aurora MySQL cluster by creating a Lambda function that sets up the necessary database users and permissions
2. Registers the Aurora MySQL cluster as a datasource in Guardium Data Protection (GDP)
3. Configures vulnerability assessment schedules and notifications

## Prerequisites

- An existing AWS Aurora MySQL cluster
- VPC and subnets where the Aurora MySQL cluster is deployed
- Security group ID of the Aurora MySQL cluster
- Master database credentials with sufficient privileges
- A Guardium Data Protection instance
- Guardium OAuth client credentials (see [Preparing Guardium](../../docs/preparing-guardium.md))

## Usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and fill in your values:
   - AWS region and resource names
   - Aurora MySQL cluster connection details
   - VPC and networking configuration
   - Guardium server details and credentials
   - VA user credentials
   - Assessment schedule and notification preferences

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## What Gets Created

This example creates:
- AWS Lambda function for VA configuration
- IAM role and policy for Lambda execution
- AWS Secrets Manager secret for database credentials
- VPC endpoint for Secrets Manager
- Security groups for Lambda and VPC endpoint
- Security group rule to allow Lambda access to Aurora MySQL
- Guardium datasource registration
- VA assessment schedule configuration
- Notification configuration for assessment results

## Configuration Details

### Aurora MySQL Cluster

The example requires an existing Aurora MySQL cluster. You need to provide:
- Cluster endpoint hostname
- Port (default: 3306)
- Database name
- Master username and password

### VA User

The Lambda function creates a `sqlguard` user in the Aurora MySQL database with the necessary permissions for vulnerability assessment. You need to provide:
- Username (default: `sqlguard`)
- Password (must be strong and secure)

### Vulnerability Assessment Schedule

Configure when VA scans should run:
- `assessment_schedule`: daily, weekly, or monthly
- `assessment_day`: Day of week (for weekly) or day of month (for monthly)
- `assessment_time`: Time in 24-hour format (e.g., "02:00")

### Notifications

Configure email notifications for assessment results:
- `enable_notifications`: Enable/disable notifications
- `notification_emails`: List of email addresses
- `notification_severity`: Minimum severity level (HIGH, MED, LOW, NONE)

## Outputs

After successful deployment, the following outputs are available:
- `lambda_function_arn`: ARN of the Lambda function
- `lambda_function_name`: Name of the Lambda function
- `security_group_id`: Security group ID for the Lambda function
- `sqlguard_username`: Username for the Guardium VA user
- `va_config_completed`: Confirmation that VA configuration is complete
- `secrets_manager_secret_arn`: ARN of the Secrets Manager secret

## Clean Up

To remove all resources created by this example:
```bash
terraform destroy
```

## Notes

- The Lambda function is deployed in the same VPC as the Aurora MySQL cluster for secure communication
- All database credentials are stored securely in AWS Secrets Manager
- The `sqlguard` user is created with minimal required permissions for VA
- SSL/TLS is enabled by default for secure connections

## Troubleshooting

### Lambda Function Fails

If the Lambda function fails to execute:
1. Check CloudWatch Logs for the Lambda function
2. Verify the Aurora MySQL cluster is accessible from the Lambda subnets
3. Ensure the master database credentials are correct
4. Verify the security group rules allow Lambda to connect to Aurora MySQL

### VA Assessment Not Running

If vulnerability assessments are not running:
1. Verify the datasource is registered in Guardium
2. Check the assessment schedule configuration
3. Review Guardium logs for any errors

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0