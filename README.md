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
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│   │DynamoDB  │  │   RDS    │  │   RDS    │  │   RDS    │  │ Redshift │      │
│   │          │  │PostgreSQL│  │ MariaDB  │  │  MySQL   │  │          │      │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                                                                             │
│   ┌──────────────┐  ┌──────────┐                                          │
│   │  Aurora      │  │   RDS    │                                          │
│   │  PostgreSQL  │  │SQL Server│                                          │
│   └──────────────┘  └──────────┘                                          │
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
   - For RDS databases (PostgreSQL, MariaDB, MySQL): Creates dedicated VA users (sqlguard/gdmmonitor) with appropriate permissions
   - For RDS SQL Server: Uses the built-in master account (rdsadmin) to create the sqlguard VA user via Lambda
   - For DynamoDB: Configures IAM roles and policies for read-only access
   - For Redshift: Creates VA users and grants system table access
3. **Guardium Integration**: Registers datasources with Guardium and configures vulnerability assessment schedules
4. **Ongoing Monitoring**: Guardium performs scheduled security assessments and generates compliance reports

## Features

- **Multi-Datastore Support**: Configure vulnerability assessment for DynamoDB, RDS PostgreSQL, Aurora PostgreSQL, RDS MariaDB, RDS MySQL, RDS SQL Server, and Redshift
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

### AWS RDS MySQL Vulnerability Assessment

Configure vulnerability assessment for AWS RDS MySQL:

```hcl
module "mysql_va" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-mysql"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "mysql.rds.amazonaws.com"
  db_port     = 3306
  db_username = "admin"
  db_password = var.db_password
  sqlguard_password = var.sqlguard_password
  
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
  datasource_name        = "mysql-production"
  datasource_description = "Production MySQL database"
  
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

### AWS RDS SQL Server Vulnerability Assessment

Configure vulnerability assessment for AWS RDS SQL Server:

```hcl
module "mssql_va" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-sql-server"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "sqlserver.rds.amazonaws.com"
  db_port     = 1433
  db_username = "admin"  # Master username from RDS instance creation
  db_password = var.db_password
  database_name = "master"
  
  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
  
  # Network configuration
  vpc_id               = "vpc-12345678"
  subnet_ids           = ["subnet-12345678", "subnet-87654321"]
  db_security_group_id = "sg-12345678"  # RDS SQL Server security group
  
  # AWS Configuration
  aws_region  = "us-east-1"
  
  # Guardium Data Protection configuration
  gdp_server   = "guardium.example.com"
  gdp_port     = "8443"
  gdp_username = "admin"
  gdp_password = var.guardium_password
  client_id    = "client1"
  client_secret = var.client_secret
  
  # Data source configuration
  datasource_name        = "sqlserver-production"
  datasource_description = "Production SQL Server database"
  application            = "Security Assessment"
  
  # Vulnerability assessment schedule
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Sunday"
  assessment_time                 = "01:00"
  
  # Notification configuration
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "HIGH"
  
  tags = {
    Environment = "Production"
    Owner       = "Security Team"
  }
}
```

**Note**: The module uses Lambda to create a dedicated `sqlguard` user with required VA permissions. The Lambda function connects using the master username (rdsadmin) to create and configure the sqlguard user, then runs in your VPC with automatic security group configuration.

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

### AWS RDS MySQL VA Configuration

Configures MySQL databases for vulnerability assessment using Lambda-based deployment.

**Key Features:**
- Creates `sqlguard` user via Lambda function
- Integrates with AWS Secrets Manager
- Deploys in VPC for secure access
- Connects directly to Guardium Data Protection
- Automatically configures security group rules for Lambda access

[Module Documentation](./modules/aws-rds-mysql/README.md)

### AWS RDS SQL Server VA Configuration

Configures SQL Server databases for vulnerability assessment using Lambda-based deployment.

**Key Features:**
- Creates `sqlguard` user via Lambda function
- Integrates with AWS Secrets Manager
- Deploys in VPC for secure access
- Connects directly to Guardium Data Protection
- Automatically configures security group rules for Lambda access
- Supports all SQL Server editions (Enterprise, Standard, Express, Web)

[Module Documentation](./modules/aws-rds-sql-server/README.md)

### AWS Redshift VA Configuration

Sets up Redshift clusters for vulnerability assessment with automated user creation.

**Key Features:**
- Creates `sqlguard` user and `gdmmonitor` group
- Uses Lambda for SQL execution
- Supports both public and private clusters
- Grants system table access permissions

[Module Documentation](./modules/aws-redshift/README.md)

## Examples

Complete working examples are provided for each supported datastore:

- [AWS DynamoDB with VA](./examples/aws-dynamodb) - DynamoDB vulnerability assessment configuration
- [AWS RDS PostgreSQL with VA](./examples/aws-rds-postgresql) - PostgreSQL vulnerability assessment configuration
- [AWS Aurora PostgreSQL with VA](./examples/aws-aurora-postgresql) - Aurora PostgreSQL vulnerability assessment configuration
- [AWS RDS MariaDB with VA](./examples/aws-rds-mariadb) - MariaDB vulnerability assessment configuration
- [AWS RDS MySQL with VA](./examples/aws-rds-mysql) - MySQL vulnerability assessment configuration
- [AWS RDS SQL Server with VA](./examples/aws-rds-sql-server) - SQL Server vulnerability assessment configuration
- [AWS Redshift with VA](./examples/aws-redshift) - Redshift vulnerability assessment configuration

Each example includes:
- Complete Terraform configuration
- Sample `terraform.tfvars.example` file
- Detailed README with setup instructions
- Architecture diagrams

## Prerequisites

Before using this module, ensure you have:

1. **Guardium Data Protection Instance**: A running GDP cluster with API access enabled
2. **Guardium Configuration**: Complete the one-time manual configurations:
   - Enable OAuth client for REST API access
   - Configure AWS credentials (for DynamoDB)
   - Set up SSH access for Terraform
3. **AWS Credentials**: Valid AWS credentials with appropriate permissions
4. **Terraform**: Version 1.0.0 or later
5. **AWS Provider**: Version 4.0.0 or later
6. **Guardium Provider**: Version 1.0.0 or later

### Required AWS Permissions

Your AWS credentials must have permissions for:
- Creating and managing IAM roles and policies
- Creating and managing Lambda functions (for MariaDB, MySQL, and Redshift)
- Creating and managing VPC resources and Security Groups
- Creating and managing Secrets Manager secrets
- Access to specific datastores (DynamoDB, RDS, Redshift)

## Security Considerations

- **Credential Management**: Store sensitive variables in AWS Secrets Manager or HashiCorp Vault
- **Least Privilege**: IAM policies grant only necessary read-only permissions
- **Network Security**: Lambda functions run in VPC with security group restrictions
- **Credential Rotation**: Regularly rotate database and API credentials
- **Audit Logging**: Enable CloudTrail for API activity monitoring
- **Encryption**: Use encrypted connections for database access

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/IBM/terraform-guardium-datastore-va.git
   cd terraform-guardium-datastore-va
   ```

2. **Choose an example**:
   ```bash
   cd examples/aws-dynamodb  # or aws-rds-postgresql, aws-rds-mariadb, aws-redshift, aws-rds-sql-server
   ```

3. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the plan**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

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
