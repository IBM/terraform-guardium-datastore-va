# AWS RDS MariaDB with Guardium Vulnerability Assessment Example

This example demonstrates how to configure an AWS RDS MariaDB database for Guardium Vulnerability Assessment (VA) and connect it to Guardium Data Protection (GDP) for security monitoring and assessment.

## Overview

This example performs two main steps:

1. **Configure Vulnerability Assessment (VA)** on the MariaDB database by creating the necessary users and permissions
2. **Connect the database to Guardium Data Protection (GDP)** for security monitoring and assessment

## Prerequisites

- An existing AWS RDS MariaDB database instance
- Access to a Guardium Data Protection (GDP) instance
- AWS credentials with permissions to create Lambda functions, IAM roles, and other required resources
- VPC and subnet IDs where the Lambda function will be deployed (must have connectivity to the RDS instance)

## Usage

### 1. Clone the repository

```bash
git clone <repository-url>
cd <repository-directory>/examples/aws-rds-mariadb
```

### 2. Configure variables

Copy the example variables file and modify it with your specific values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific configuration values:

```hcl
# General Configuration
aws_region  = "us-west-2"
name_prefix = "your-prefix"

# Database Configuration
db_host     = "your-mariadb-instance.rds.amazonaws.com"
db_port     = 3306
db_username = "admin"
db_password = "your-secure-password"
gdmmonitor_password = "secure-password-for-gdmmonitor"

# Network Configuration
vpc_id      = "vpc-12345678"
subnet_ids  = ["subnet-12345678", "subnet-87654321"]

# Guardium Data Protection Configuration
gdp_server   = "your-guardium-server.example.com"
gdp_username = "admin"
gdp_password = "your-gdp-password"
client_id    = "client1"
client_secret = "your-client-secret"

# Vulnerability Assessment Configuration
enable_vulnerability_assessment = true
assessment_schedule = "weekly"
assessment_day = "Monday"
assessment_time = "02:00"

# Notification Configuration
enable_notifications = true
notification_emails = ["security-team@example.com"]
notification_severity = "HIGH"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Apply the configuration

```bash
terraform apply
```

Review the planned changes and type `yes` to apply them.

## Module Details

This example uses two main modules:

1. **aws-rds-mariadb** - Configures the MariaDB database for vulnerability assessment by:
   - Creating a `gdmmonitor` user with the necessary permissions
   - Granting required permissions for Guardium VA
   - Deploying a Lambda function to execute the configuration

2. **connect-datasource-to-va** - Connects the database to Guardium Data Protection by:
   - Registering the database as a data source in GDP
   - Configuring vulnerability assessment schedules
   - Setting up notification preferences

## Inputs

| Name                            | Description                                                              | Type           | Default             | Required |
|---------------------------------|--------------------------------------------------------------------------|----------------|---------------------|:--------:|
| aws_region                      | AWS region where resources will be created                               | `string`       | `"us-east-1"`       |    no    |
| name_prefix                     | Prefix to use for resource names                                         | `string`       | `"rds-mariadb-sql"` |    no    |
| db_host                         | Host of the MariaDB database                                             | `string`       | n/a                 |   yes    |
| db_port                         | Port for MariaDB database                                                | `number`       | `3306`              |    no    |
| db_username                     | Username for the MariaDB database                                        | `string`       | `"guardium_admin"`  |    no    |
| db_password                     | Password for the MariaDB database                                        | `string`       | n/a                 |   yes    |
| gdmmonitor_password             | Password for the Guardium VA user                                        | `string`       | n/a                 |   yes    |
| vpc_id                          | The ID of the VPC to deploy the lambda into                              | `string`       | n/a                 |   yes    |
| subnet_ids                      | The subnet IDs to deploy the lambda into                                 | `list(string)` | n/a                 |   yes    |
| gdp_server                      | The hostname or IP address of the Guardium server                        | `string`       | n/a                 |   yes    |
| gdp_username                    | The username to login to Guardium                                        | `string`       | n/a                 |   yes    |
| gdp_password                    | The password for logging in to Guardium                                  | `string`       | n/a                 |   yes    |
| client_id                       | The client ID used to create the GDP register_oauth_client client_secret | `string`       | `"client1"`         |    no    |
| client_secret                   | The client secret output from grdapi register_oauth_client               | `string`       | n/a                 |   yes    |
| enable_vulnerability_assessment | Whether to enable vulnerability assessment                               | `bool`         | `true`              |    no    |
| assessment_schedule             | Schedule for vulnerability assessments                                   | `string`       | `"weekly"`          |    no    |
| assessment_day                  | Day to run the assessment                                                | `string`       | `"Monday"`          |    no    |
| assessment_time                 | Time to run the assessment in 24-hour format                             | `string`       | `"02:00"`           |    no    |
| enable_notifications            | Whether to enable notifications for assessment results                   | `bool`         | `true`              |    no    |
| notification_emails             | List of email addresses to notify about assessment results               | `list(string)` | `[]`                |    no    |
| notification_severity           | Minimum severity level for notifications                                 | `string`       | `"HIGH"`            |    no    |

## Outputs

| Name                                 | Description                                                     |
|--------------------------------------|-----------------------------------------------------------------|
| mariadb_instance_address             | Address of the RDS MariaDB instance                             |
| mariadb_instance_port                | Port of the RDS MariaDB instance                                |
| mariadb_instance_username            | Username for the MariaDB database                               |
| sqlguard_username                    | Username for the Guardium VA user                               |
| va_config_status                     | Status of the VA configuration                                  |
| gdp_datasource_name                  | Name of the registered data source in Guardium                  |
| gdp_vulnerability_assessment_enabled | Whether vulnerability assessment is enabled for the data source |
| gdp_assessment_schedule              | Schedule for vulnerability assessments                          |
| gdp_notifications_enabled            | Whether notifications are enabled for assessment results        |
| gdp_notification_recipients          | Email addresses that will receive notifications                 |
| gdp_server                           | Hostname of the Guardium Data Protection server                 |

## Notes

- The Lambda function is deployed in the specified VPC and subnets to ensure network connectivity to the MariaDB instance
- All database credentials are handled securely using AWS Secrets Manager
- The module creates the necessary IAM roles and policies for the Lambda function to operate
- The example assumes you have already created an OAuth client in Guardium and have the client secret
