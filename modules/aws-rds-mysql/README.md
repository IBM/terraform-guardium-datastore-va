<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS MySQL Vulnerability Assessment Configuration Module

This Terraform module configures an AWS RDS MySQL database for Guardium Vulnerability Assessment (VA) and connects it to Guardium Data Protection (GDP). It creates the necessary users and permissions required for Guardium to perform security assessments and entitlement reports.

## Architecture

The module deploys the following components:
1. A Lambda function in your VPC that configures the MySQL database
2. AWS Secrets Manager to securely store database credentials
3. IAM roles and policies for the Lambda function
4. VPC endpoints for secure communication
5. Connection to Guardium Data Protection for vulnerability assessment

## Features

- Creates a `sqlguard` user with the necessary permissions for vulnerability assessment
- Grants the required permissions for Guardium VA to work properly
- Configures the database for Guardium Vulnerability Assessment
- Deploys a Lambda function to execute the configuration in the VPC where the MySQL instance resides
- Connects the database to Guardium Data Protection for ongoing security monitoring
- Configures scheduled vulnerability assessments and notifications

## Prerequisites

- An existing AWS RDS MySQL database instance (version 10.x or above)
- The user executing the module must have superuser privileges on the database
- The database must be accessible from the Lambda function (in the same VPC or with proper network connectivity)
- The database security group must allow connections from Guardium server on port 3306
- VPC and subnet IDs where the Lambda function will be deployed
- Access to a Guardium Data Protection (GDP) instance
- OAuth client credentials for the Guardium API

## Usage

### Basic Usage

```hcl
module "aws-rds-mysql" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-mysql"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "your-mysql-instance.rds.amazonaws.com"
  db_port     = 3306
  db_username = "admin"
  db_password = "your-password"
  
  # Network configuration
  vpc_id      = "vpc-xxxxxx"
  subnet_ids  = ["subnet-xxxxxx", "subnet-xxxxxx"]
  aws_region  = "us-east-1"
}
```

### Custom sqlguard User

```hcl
module "aws-rds-mysql" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-mysql"

  name_prefix = "myproject"
  
  # Database connection details
  db_host          = "your-mysql-instance.rds.amazonaws.com"
  db_port          = 3306
  db_username      = "admin"
  db_password      = "your-password"
  
  # Custom sqlguard credentials
  sqlguard_username = "custom_guard"
  sqlguard_password = "CustomPassword123!"
  
  # Network configuration
  vpc_id      = "vpc-xxxxxxxx"
  subnet_ids  = ["subnet-xxxxxxxx"]
  aws_region  = "us-west-2"
}
```

## Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name_prefix | Prefix to use for resource names | `string` |
| db_host | Hostname or IP address of the MySQL database | `string` |
| db_username | Username for the MySQL database (must have superuser privileges) | `string` |
| db_password | Password for the MySQL database | `string` |
| sqlguard_password | Password for the sqlguard user | `string` |
| vpc_id | ID of the VPC where the Lambda function will be deployed | `string` |
| subnet_ids | List of subnet IDs where the Lambda function will be deployed | `list(string)` |
| aws_region | AWS region where resources will be created | `string` |
| gdp_server | The hostname or IP address of the Guardium server | `string` |
| gdp_username | The username to login to Guardium | `string` |
| gdp_password | The password for logging in to Guardium | `string` |
| client_secret | The client secret output from grdapi register_oauth_client | `string` |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| db_port | Port for the MySQL database | `number` | `3306` |
| tags | Tags to apply to all resources | `map(string)` | `{ Purpose = "guardium-va-config", Owner = "your-email@example.com" }` |
| gdp_port | The port of the Guardium server | `string` | `"8443"` |
| client_id | The client ID used to create the GDP register_oauth_client client_secret | `string` | `"client1"` |
| datasource_name | A unique name for the datasource on the Guardium system | `string` | `"rds-mysql-va"` |
| datasource_description | Description of the datasource | `string` | `"MySQL data source onboarded via Terraform"` |
| application | Application type for the datasource | `string` | `"Security Assessment"` |
| severity_level | Severity classification for the datasource (LOW, NONE, MED, HIGH) | `string` | `"MED"` |
| enable_vulnerability_assessment | Whether to enable vulnerability assessment for the data source | `bool` | `true` |
| assessment_schedule | Schedule for vulnerability assessments (e.g., daily, weekly, monthly) | `string` | `"weekly"` |
| assessment_day | Day to run the assessment (e.g., Monday, 1) | `string` | `"Monday"` |
| assessment_time | Time to run the assessment in 24-hour format (e.g., 02:00) | `string` | `"02:00"` |
| enable_notifications | Whether to enable notifications for assessment results | `bool` | `true` |
| notification_emails | List of email addresses to notify about assessment results | `list(string)` | `[]` |
| notification_severity | Minimum severity level for notifications (HIGH, MED, LOW, NONE) | `string` | `"HIGH"` |

For a complete list of all input variables, please refer to the [variables.tf](./variables.tf) file.

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user (sqlguard) |
| sqlguard_password | Password for the sqlguard user (sensitive) |

## Implementation Details

The module performs the following actions:

1. **Secrets Management**:
   - Creates an AWS Secrets Manager secret to store database credentials securely
   - Configures a VPC endpoint for Secrets Manager to allow secure access from the Lambda function

2. **Lambda Function Deployment**:
   - Creates an IAM role and policy for the Lambda function
   - Deploys a Lambda function in the specified VPC and subnets
   - Configures security groups for the Lambda function

3. **Database Configuration**:
   - The Lambda function connects to the MySQL database using the provided credentials
   - Creates or updates the `sqlguard` user with the specified password
   - Grants the necessary permissions for Guardium VA:
     - SELECT on mysql.user
     - SELECT on mysql.db
     - SHOW DATABASES on *.*
   - Flushes privileges to apply the changes

4. **Guardium Data Protection Integration**:
   - Registers the database as a data source in Guardium Data Protection
   - Configures vulnerability assessment schedules
   - Sets up notification preferences for assessment results

## Network Configuration for Guardium Access

**Important**: This module configures the database user (`sqlguard`) but does **not** automatically configure network access from Guardium to your RDS instance. You must manually add a security group rule to allow Guardium's IP address.

### Why This Is Required

The module creates:
-  Lambda function → MySQL connectivity (automatic)
-  Database user `sqlguard` with proper permissions (automatic)
-  Guardium server → MySQL connectivity (manual configuration required)

Guardium needs direct network access to perform vulnerability assessments. Without this, you'll see connection timeout errors.

### Quick Setup

1. **Get Guardium's public IP** (run on Guardium server):
   ```bash
   curl ifconfig.me
   ```

2. **Find your MySQL security group**:
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier <your-instance-id> \
     --region <your-region> \
     --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
     --output text
   ```

3. **Add security group rule**:
   ```bash
   aws ec2 authorize-security-group-ingress \
     --group-id sg-xxxxxxxxxxxxxxxxx \
     --protocol tcp \
     --port 3306 \
     --cidr xxx.xxx.xxx.xxx/32 \
     --region <your-region> \
     --description "Guardium VA access"
   ```

4. **Verify the rule**:
   ```bash
   aws ec2 describe-security-groups \
     --group-ids sg-xxxxxxxxxxxxxxxxx \
     --region <your-region> \
     --query 'SecurityGroups[0].IpPermissions[?ToPort==`3306`]' \
     --output table
   ```

5. **Test from Guardium**:
   ```bash
   mysql -h your-mysql-host.rds.amazonaws.com -P 3306 -u sqlguard -p -e "SELECT 1;"
   ```

For detailed instructions and troubleshooting, see the [example README](../../examples/aws-rds-mysql/README.md#configuring-network-access-for-guardium).

## Security Considerations

- All database credentials are stored securely in AWS Secrets Manager
- The Lambda function runs in your VPC with minimal permissions
- Network access is restricted using security groups
- All SQL queries are properly parameterized to prevent SQL injection vulnerabilities
- Sensitive variables are marked as such to prevent exposure in logs

## Troubleshooting

Common issues and their solutions:

1. **Lambda function fails to connect to the database**:
   - Ensure the security groups allow traffic from the Lambda function to the database
   - Verify that the database is in the same VPC or accessible via VPC peering
   - Check that the provided database credentials are correct
   - Check the logs in the created cloudwatch log group

2. **Permission errors when configuring the database**:
   - Ensure the database user has superuser privileges
   - Check that the database is not in a read-only mode

3. **Guardium connection issues**:
   - Verify that the Guardium server is accessible from the Lambda function
   - Check that the provided Guardium credentials and OAuth client details are correct

