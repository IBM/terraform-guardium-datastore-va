# Guardium Datastore Vulnerability Assessment Terraform Module

Terraform module which configures AWS datastores for vulnerability assessment and connects them to IBM Guardium Data Protection (GDP).

## Scope

This module provides automated configuration of datastores for vulnerability assessment with IBM Guardium Data Protection. It handles the setup of necessary database users, permissions, IAM roles, and the registration of datasources with Guardium for ongoing security monitoring.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                   Guardium Datastore VA Terraform Module                    │
│                                                                             │
│  Orchestrates configuration and setup of datastores for vulnerability       │
│  assessment and onboards them to Guardium Data Protection                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Configures
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                         AWS Datastore Resources                             │
│                                                                             │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│   │  DynamoDB    │  │  RDS         │  │  RDS         │  │  Redshift    │  │
│   │              │  │  PostgreSQL  │  │  MariaDB     │  │              │  │
│   └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
│   ┌──────────────┐                                                         │
│   │  Aurora      │                                                         │
│   │  PostgreSQL  │                                                         │
│   └──────────────┘                                                         │
│                                                                             │
│   • Creates VA users (sqlguard/gdmmonitor)                                  │
│   • Configures IAM roles and policies                                       │
│   • Sets up database permissions                                            │
│   • Prepares datastores for security scanning                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Registers & Connects
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                      Guardium Data Protection (GDP)                         │
│                                                                             │
│   • Datasource Registration                                                 │
│   • Vulnerability Assessment Scheduling                                     │
│   • Security Scanning & Compliance Checks                                   │
│   • Assessment Reports & Notifications                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Datastore Configuration**: The module configures datastores with necessary users, permissions, and IAM roles required for vulnerability assessment
2. **Database Setup**:
   - For RDS databases (PostgreSQL, MariaDB, Oracle): Creates dedicated VA users (sqlguard/gdmmonitor) with appropriate permissions
   - For Aurora PostgreSQL: Creates sqlguard user and gdmmonitor group via Lambda
   - For DynamoDB: Configures IAM roles and policies for read-only access
   - For Redshift: Creates VA users and grants system table access
3. **Guardium Integration**: Registers datasources with Guardium and configures vulnerability assessment schedules
4. **Ongoing Monitoring**: Guardium performs scheduled security assessments and generates compliance reports

## Features

- **Multi-Datastore Support**: Configure vulnerability assessment for DynamoDB, RDS PostgreSQL, Aurora PostgreSQL, RDS MariaDB, RDS Oracle, and Redshift
- **Automated User Creation**: Automatically creates and configures database users with appropriate permissions
- **IAM Integration**: Sets up IAM roles and policies for secure access
- **Lambda-Based Configuration**: Uses AWS Lambda for database configuration, eliminating local client requirements
- **Guardium Integration**: Seamlessly registers datasources with Guardium Data Protection
- **Scheduled Assessments**: Configure automated vulnerability assessment schedules
- **Notification Support**: Set up email notifications for assessment results
- **Security Best Practices**: Implements least-privilege access and secure credential management

## Usage

### AWS DynamoDB Vulnerability Assessment

Configure vulnerability assessment for AWS DynamoDB tables:

```hcl
module "datastore-va_aws-dynamodb" {
  source = "IBM/datastore-va/guardium//modules/aws-dynamodb"

  # IAM Configuration
  iam_role_name        = "guardium-dynamodb-va-role"
  iam_policy_name      = "guardium-dynamodb-va-policy"
  iam_role_description = "IAM role for Guardium vulnerability assessment of DynamoDB"
  
  # Connection Configuration
  connection_username = var.aws_access_key_id
  connection_password = var.aws_secret_access_key
  
  # Tags
  tags = {
    Environment = "Production"
    Owner       = "Security Team"
  }
}

# Connect to Guardium Data Protection
module "connect_dynamodb_to_gdp" {
  source = "IBM/datastore-va/guardium//modules/connect-datasource-to-gdp"
  
  gdp_server   = "guardium.example.com"
  gdp_username = "admin"
  gdp_password = var.guardium_password
  client_id    = "client1"
  client_secret = var.client_secret
  
  datasource_name = "dynamodb-production"
  datasource_type = "DYNAMODB"
  hostname        = "dynamodb.us-east-1.amazonaws.com"
  
  # Use AWS Secrets Manager for authentication
  aws_secrets_manager_name   = "my-aws-config"
  aws_secrets_manager_region = "us-east-1"
  aws_secrets_manager_secret = "dynamodb-credentials"
}
```

### AWS RDS PostgreSQL Vulnerability Assessment

Configure vulnerability assessment for AWS RDS PostgreSQL:

```hcl
module "postgres_va" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-postgresql"

  db_host     = "postgres.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "postgres"
  db_password = var.db_password
  
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
}

# Connect to Guardium Data Protection
module "connect_postgres_to_gdp" {
  source = "IBM/datastore-va/guardium//modules/connect-datasource-to-gdp"
  
  gdp_server   = "guardium.example.com"
  gdp_username = "admin"
  gdp_password = var.guardium_password
  client_id    = "client1"
  client_secret = var.client_secret
  
  datasource_name = "postgres-production"
  datasource_type = "POSTGRESQL"
  hostname        = "postgres.rds.amazonaws.com"
  port            = 5432
  database_name   = "postgres"
  
  connection_username = module.postgres_va.sqlguard_username
  connection_password = module.postgres_va.sqlguard_password
  
  enable_vulnerability_assessment = true
  assessment_schedule             = "WEEKLY"
  assessment_day                  = "Sunday"
  assessment_time                 = "01:00"
}
```

### AWS Aurora PostgreSQL Vulnerability Assessment

Configure vulnerability assessment for AWS Aurora PostgreSQL:

```hcl
module "aurora_postgresql_va" {
  source = "IBM/datastore-va/guardium//modules/aws-aurora-postgresql"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "postgres"
  db_password = var.db_password
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
  
  # Network configuration
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]
  aws_region  = "us-east-1"
}

# Connect to Guardium Data Protection
module "connect_aurora_to_gdp" {
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"
  
  datasource_payload = local.aurora_postgres_config_json_encoded
  
  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = "guardium.example.com"
  gdp_username  = "admin"
  gdp_port      = "8443"
  
  # Vulnerability Assessment Configuration
  datasource_name                 = "aurora-postgresql-production"
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Monday"
  assessment_time                 = "02:00"
  
  # Notification Configuration
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "HIGH"
  
  depends_on = [module.aurora_postgresql_va]
}
```

### AWS RDS MariaDB Vulnerability Assessment

Configure vulnerability assessment for AWS RDS MariaDB:

```hcl
module "mariadb_va" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-mariadb"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "mariadb.rds.amazonaws.com"
  db_port     = 3306
  db_username = "admin"
  db_password = var.db_password
  gdmmonitor_password = var.gdmmonitor_password
  
  # Network configuration
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]
  aws_region  = "us-east-1"
  
  # Guardium Data Protection configuration
  gdp_server   = "guardium.example.com"
  gdp_username = "admin"
  gdp_password = var.guardium_password
  client_id    = "client1"
  client_secret = var.client_secret
  
  # Data source configuration
  datasource_name        = "mariadb-production"
  datasource_description = "Production MariaDB database"
  
  # Vulnerability assessment schedule
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Sunday"
  assessment_time                 = "01:00"
  
  # Notification configuration
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "MED"
}
```

### AWS Redshift Vulnerability Assessment

Configure vulnerability assessment for AWS Redshift:

```hcl
module "redshift_va" {
  source = "IBM/datastore-va/guardium//modules/aws-redshift"
  
  name_prefix = "guardium"
  aws_region  = "us-east-1"
  
  # Redshift Connection Details
  redshift_host     = "redshift-cluster.region.redshift.amazonaws.com"
  redshift_port     = 5439
  redshift_database = "dev"
  redshift_username = "admin"
  redshift_password = var.redshift_password
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
  
  # Network Configuration (for private Redshift)
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
}

# Connect to Guardium Data Protection
module "connect_redshift_to_gdp" {
  source = "IBM/datastore-va/guardium//modules/connect-datasource-to-gdp"
  
  gdp_server   = "guardium.example.com"
  gdp_username = "admin"
  gdp_password = var.guardium_password
  client_id    = "client1"
  client_secret = var.client_secret
  
  datasource_name = "redshift-production"
  datasource_type = "REDSHIFT"
  hostname        = "redshift-cluster.region.redshift.amazonaws.com"
  port            = 5439
  database_name   = "dev"
  
  connection_username = module.redshift_va.sqlguard_username
  connection_password = module.redshift_va.sqlguard_password
  
  enable_vulnerability_assessment = true
  assessment_schedule             = "MONTHLY"
  assessment_day                  = "1"
  assessment_time                 = "03:00"
}
```

### AWS Oracle Vulnerability Assessment

Configure vulnerability assessment for AWS RDS Oracle or Oracle Autonomous Database:

```hcl
module "oracle_va" {
  source = "IBM/datastore-va/guardium//modules/aws-oracle"

  name_prefix = "myproject"
  
  # Database connection details
  db_host         = "oracle-db.xxxxx.us-east-1.rds.amazonaws.com"
  db_port         = 1521
  db_service_name = "ORCL"
  db_username     = "admin"
  db_password     = var.db_password
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
  
  # Network configuration
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  aws_region = "us-east-1"
}

# Connect to Guardium Data Protection
module "connect_oracle_to_gdp" {
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"
  
  datasource_payload = local.oracle_config_json_encoded
  
  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = "guardium.example.com"
  gdp_username  = "admin"
  gdp_port      = "8443"
  
  # Vulnerability Assessment Configuration
  datasource_name                 = "oracle-production"
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Monday"
  assessment_time                 = "02:00"
  
  # Notification Configuration
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "HIGH"
  
  depends_on = [module.oracle_va]
}
```

## Modules

### AWS DynamoDB VA Configuration

Configures IAM roles and policies for Guardium to perform vulnerability assessment on DynamoDB tables.

**Key Features:**
- Creates IAM role with trust policy for Guardium
- Configures read-only permissions for DynamoDB metadata
- Supports AWS Secrets Manager integration
- Provides connection credentials for Guardium

[Module Documentation](./modules/aws-dynamodb/README.md)

### AWS RDS PostgreSQL VA Configuration

Creates the necessary database users and permissions for Guardium vulnerability assessment on RDS PostgreSQL.

**Key Features:**
- Creates `sqlguard` user with required permissions
- Configures `gdmmonitor` group
- Supports both local and EC2-based execution
- Executes VA configuration scripts

[Module Documentation](./modules/aws-rds-postgresql/README.md)

### AWS Aurora PostgreSQL VA Configuration

Creates the necessary database users and permissions for Guardium vulnerability assessment on Aurora PostgreSQL clusters.

**Key Features:**
- Creates `sqlguard` user with required permissions
- Configures `gdmmonitor` group
- Uses Lambda for SQL execution in VPC
- Integrates with AWS Secrets Manager
- Connects directly to Guardium Data Protection

[Module Documentation](./modules/aws-aurora-postgresql/README.md)

### AWS RDS MariaDB VA Configuration

Configures MariaDB databases for vulnerability assessment using Lambda-based deployment.

**Key Features:**
- Creates `gdmmonitor` user via Lambda function
- Integrates with AWS Secrets Manager
- Deploys in VPC for secure access
- Connects directly to Guardium Data Protection

[Module Documentation](./modules/aws-rds-mariadb/README.md)

### AWS Redshift VA Configuration

Sets up Redshift clusters for vulnerability assessment with automated user creation.

**Key Features:**
- Creates `sqlguard` user and `gdmmonitor` group
- Uses Lambda for SQL execution
- Supports both public and private clusters
- Grants system table access permissions

[Module Documentation](./modules/aws-redshift/README.md)

### AWS Oracle VA Configuration

Configures Oracle databases (RDS or Autonomous) for vulnerability assessment using Lambda-based deployment.

**Key Features:**
- Creates `gdmmonitor` role with required privileges
- Creates `sqlguard` user via Lambda function
- Uses Oracle Instant Client for connectivity
- Integrates with AWS Secrets Manager
- Connects directly to Guardium Data Protection

[Module Documentation](./modules/aws-oracle/README.md)

## Examples

Complete working examples are provided for each supported datastore:

- [AWS DynamoDB with VA](./examples/aws-dynamodb) - DynamoDB vulnerability assessment configuration
- [AWS RDS PostgreSQL with VA](./examples/aws-rds-postgresql) - PostgreSQL vulnerability assessment configuration
- [AWS Aurora PostgreSQL with VA](./examples/aws-aurora-postgresql) - Aurora PostgreSQL vulnerability assessment configuration
- [AWS RDS MariaDB with VA](./examples/aws-rds-mariadb) - MariaDB vulnerability assessment configuration
- [AWS RDS Oracle with VA](./examples/aws-oracle) - Oracle (RDS/Autonomous) vulnerability assessment configuration
- [AWS Redshift with VA](./examples/aws-redshift) - Redshift vulnerability assessment configuration

Each example includes:
- Complete Terraform configuration
- Sample `terraform.tfvars.example` file
- Detailed README with setup instructions
- Architecture diagrams

## Getting Started

Follow these steps to configure vulnerability assessment for your AWS datastores:

### Step 0: Prerequisites

Before you begin, ensure you have:

#### Required Infrastructure
- **AWS Account** with an existing database (RDS PostgreSQL, Aurora PostgreSQL, MariaDB, Oracle, Redshift, or DynamoDB)
- **Guardium Data Protection (GDP)** cluster deployed and accessible
- **Network connectivity** between your workstation and Guardium server

#### Required Tools
- **Terraform** >= 1.0.0 ([Install Terraform](https://developer.hashicorp.com/terraform/downloads))
- **AWS CLI** configured with credentials ([Install AWS CLI](https://aws.amazon.com/cli/))
- **Git** for cloning the repository

#### Required Permissions
Your AWS credentials must have permissions for:
- Creating and managing IAM roles and policies
- Creating and managing Lambda functions
- Creating and managing VPC resources and Security Groups
- Creating and managing Secrets Manager secrets
- Access to your specific datastore (RDS, DynamoDB, etc.)

### Step 1: Prepare Your Database

Ensure your database is ready for vulnerability assessment:

1. **Verify database is running** and accessible
2. **Note down connection details**:
   - Hostname/Endpoint
   - Port
   - Database name (or service name for Oracle)
   - Admin username and password
3. **Identify network configuration**:
   - VPC ID
   - Subnet IDs (where Lambda will run)
   - Security group IDs

**Get database information using AWS CLI:**

```bash
# For RDS databases (PostgreSQL, MariaDB, Oracle)
aws rds describe-db-instances \
  --db-instance-identifier your-db-name \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,VpcId:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName}' \
  --output json

# Get subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name your-subnet-group-name \
  --query 'DBSubnetGroups[0].Subnets[*].SubnetIdentifier' \
  --output json
```

### Step 2: Prepare Your Guardium Cluster

Configure your Guardium Data Protection cluster for API access:

#### 2.1: Enable OAuth Client

SSH into your Guardium server and register an OAuth client:

```bash
# SSH to Guardium server
ssh root@your-guardium-server

# Register OAuth client
grdapi register_oauth_client client_id=client1 grant_types=password

# Save the client_secret output - you'll need this later
```

**Important**: Save the `client_secret` value securely. You'll use it in your Terraform configuration.

#### 2.2: Verify API Access

Test that the Guardium API is accessible:

```bash
# From your workstation, test connectivity
curl -k https://your-guardium-server:8443/restAPI/online_users

# You should see a response (even if authentication fails, it confirms the API is reachable)
```

#### 2.3: Note Guardium Credentials

You'll need:
- **Guardium server hostname or IP**: `guardium.example.com`
- **Guardium port**: `8443` (default)
- **Admin username**: Usually `admin`
- **Admin password**: Your Guardium admin password
- **OAuth client ID**: `client1` (from Step 2.1)
- **OAuth client secret**: The secret from Step 2.1

### Step 3: Clone and Configure

#### 3.1: Clone the Repository

```bash
git clone https://github.com/IBM/terraform-guardium-datastore-va.git
cd terraform-guardium-datastore-va
```

#### 3.2: Choose Your Database Type

Navigate to the appropriate example directory:

```bash
# For RDS PostgreSQL
cd examples/aws-rds-postgresql

# For Aurora PostgreSQL
cd examples/aws-aurora-postgresql

# For RDS MariaDB
cd examples/aws-rds-mariadb

# For RDS Oracle
cd examples/aws-oracle

# For Redshift
cd examples/aws-redshift

# For DynamoDB
cd examples/aws-dynamodb
```

#### 3.3: Prepare Configuration File

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

#### 3.4: Edit Configuration

Open `terraform.tfvars` and fill in your values:

```hcl
#------------------------------------------------------------------------------
# Database Configuration (from Step 1)
#------------------------------------------------------------------------------
db_host     = "your-database.xxxxx.us-east-1.rds.amazonaws.com"
db_port     = 5432  # or 3306 for MariaDB, 1521 for Oracle, 5439 for Redshift
db_name     = "postgres"  # or service_name for Oracle
db_username = "admin"
db_password = "your-database-password"

#------------------------------------------------------------------------------
# Network Configuration (from Step 1)
#------------------------------------------------------------------------------
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
aws_region = "us-east-1"

#------------------------------------------------------------------------------
# Guardium Configuration (from Step 2)
#------------------------------------------------------------------------------
gdp_server    = "guardium.example.com"
gdp_port      = "8443"
gdp_username  = "admin"
gdp_password  = "your-guardium-password"
client_id     = "client1"
client_secret = "your-client-secret-from-step-2"

#------------------------------------------------------------------------------
# VA User Configuration
#------------------------------------------------------------------------------
sqlguard_username = "sqlguard"
sqlguard_password = "create-a-secure-password"

#------------------------------------------------------------------------------
# Assessment Schedule
#------------------------------------------------------------------------------
enable_vulnerability_assessment = true
assessment_schedule             = "weekly"
assessment_day                  = "Monday"
assessment_time                 = "02:00"

#------------------------------------------------------------------------------
# Notifications
#------------------------------------------------------------------------------
enable_notifications  = true
notification_emails   = ["security-team@example.com"]
notification_severity = "HIGH"
```

**Security Note**: Never commit `terraform.tfvars` to version control. Add it to `.gitignore`.

### Step 4: Deploy with Terraform

#### 4.1: Initialize Terraform

Download required providers and modules:

```bash
terraform init
```

#### 4.2: Review the Plan

See what resources will be created:

```bash
terraform plan
```

Review the output carefully. You should see:
- Lambda function and IAM roles
- Security groups
- Secrets Manager secret
- VPC endpoint (for Secrets Manager)
- Guardium datasource registration

#### 4.3: Apply Configuration

Deploy the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Deployment time**: Typically 2-5 minutes depending on the database type.

### Step 5: Verify Deployment

#### 5.1: Check Terraform Outputs

After successful deployment, review the outputs:

```bash
terraform output
```

You should see:
- `sqlguard_username`: The VA user created
- `lambda_function_name`: Name of the configuration Lambda
- `datasource_name`: Name registered in Guardium
- `gdp_connection_status`: Should show "Connected"

#### 5.2: Verify Lambda Execution

Check CloudWatch Logs to confirm the Lambda ran successfully:

```bash
aws logs tail /aws/lambda/<lambda-function-name> --follow
```

Look for "VA configuration completed successfully" message.

#### 5.3: Verify Database Objects

Connect to your database and verify the VA user was created:

**For PostgreSQL/Aurora:**
```sql
SELECT usename FROM pg_user WHERE usename = 'sqlguard';
SELECT rolname FROM pg_roles WHERE rolname = 'gdmmonitor';
```

**For MariaDB:**
```sql
SELECT User FROM mysql.user WHERE User = 'gdmmonitor';
```

**For Oracle:**
```sql
SELECT USERNAME FROM DBA_USERS WHERE USERNAME = 'SQLGUARD';
SELECT ROLE FROM DBA_ROLES WHERE ROLE = 'GDMMONITOR';
```

#### 5.4: Verify Guardium Registration

1. Log into your Guardium console
2. Navigate to **Data Sources** → **Datasources**
3. Find your datasource (name from `terraform output datasource_name`)
4. Verify status shows as "Connected"
5. Check **Vulnerability Assessment** → **Schedules** to confirm the assessment schedule

### Step 6: Run Your First Assessment (Optional)

Trigger an immediate vulnerability assessment to test:

1. In Guardium console, go to **Vulnerability Assessment** → **Assessments**
2. Click **Run Assessment**
3. Select your datasource
4. Click **Run Now**
5. Monitor the assessment progress
6. Review results when complete

### Troubleshooting

If you encounter issues:

**Lambda fails to execute:**
- Check CloudWatch Logs: `aws logs tail /aws/lambda/<function-name> --follow`
- Verify security groups allow Lambda → Database connectivity
- Confirm database credentials are correct

**Guardium connection fails:**
- Verify Guardium server is accessible: `curl -k https://your-guardium:8443/restAPI/online_users`
- Check OAuth client secret is correct
- Confirm Guardium credentials are valid

**Database user creation fails:**
- Verify admin user has sufficient privileges (DBA for Oracle, superuser for PostgreSQL)
- Check database is not in restricted mode
- Review Lambda logs for specific error messages

**For detailed troubleshooting**, see the README in your specific example directory.

## Security Considerations

- **Credential Management**: Store sensitive variables in AWS Secrets Manager or HashiCorp Vault
- **Least Privilege**: IAM policies grant only necessary read-only permissions
- **Network Security**: Lambda functions run in VPC with security group restrictions
- **Credential Rotation**: Regularly rotate database and API credentials
- **Audit Logging**: Enable CloudTrail for API activity monitoring
- **Encryption**: Use encrypted connections for database access

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| guardium | >= 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |
| guardium | >= 1.0.0 |

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Support

For issues and questions:
- Create an issue in this repository
- Contact the maintainers listed in [MAINTAINERS.md](MAINTAINERS.md)

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

```text
#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#
```

## Authors

Module is maintained by IBM with help from [these awesome contributors](https://github.com/IBM/terraform-guardium-datastore-va/graphs/contributors).

## Additional Resources

- [IBM Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [Guardium Vulnerability Assessment Guide](https://www.ibm.com/docs/en/guardium/12.2?topic=assessment-vulnerability)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
