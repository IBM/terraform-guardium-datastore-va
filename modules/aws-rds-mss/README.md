<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS SQL Server Vulnerability Assessment Module

This Terraform module configures AWS RDS SQL Server instances for IBM Guardium Vulnerability Assessment (VA).

## Overview

This module uses AWS Lambda to automatically create and configure a dedicated `sqlguard` user for Guardium Vulnerability Assessment on AWS RDS SQL Server instances.

**How it works:**
1. Lambda connects to SQL Server using the master account (`rdsadmin`)
2. Creates a dedicated `sqlguard` login and user
3. Grants required server-level and database-level permissions
4. Configures `gdmmonitor` role in all user databases
5. Stores credentials securely in AWS Secrets Manager

## Features

-  Automated `sqlguard` user creation via Lambda
-  Secure credential storage in AWS Secrets Manager
-  VPC-based deployment with automatic security group configuration
-  Support for all SQL Server editions (Enterprise, Standard, Express, Web)


## Prerequisites

- AWS RDS SQL Server instance
- Master account (`rdsadmin`) credentials
- VPC with private subnets and NAT gateway
- Terraform >= 1.0.0
- AWS Provider ~> 5.0

## Usage

### Basic Example

```hcl
module "mssql_va_config" {
  source = "../../modules/aws-rds-mss"

  name_prefix = "my-app"

  # Database Connection
  db_host     = "my-sqlserver.abc123.us-east-1.rds.amazonaws.com"
  db_port     = 1433
  db_username = "rdsadmin"  # AWS RDS SQL Server master account
  db_password = var.rdsadmin_password
  database_name = "master"

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # Network Configuration
  vpc_id               = "vpc-12345678"
  subnet_ids           = ["subnet-12345678", "subnet-87654321"]
  db_security_group_id = "sg-12345678"

  # General Configuration
  aws_region = "us-east-1"
  
  tags = {
    Environment = "production"
    Application = "guardium-va"
  }
}
```

### Complete Example with VA Registration

```hcl
# Step 1: Create sqlguard user via Lambda
module "mssql_va_config" {
  source = "../../modules/aws-rds-mss"

  name_prefix   = "my-app"
  db_host       = var.db_host
  db_port       = 1433
  db_username   = "rdsadmin"
  db_password   = var.rdsadmin_password
  database_name = "master"
  
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password
  
  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  db_security_group_id = var.db_security_group_id
  
  aws_region = var.aws_region
  tags       = var.tags
}

# Step 2: Create datasource configuration
locals {
  mssql_config = templatefile("${path.module}/templates/mssql_datasource.tpl", {
    datasource_name        = "my-sqlserver-va"
    datasource_hostname    = var.db_host
    datasource_port        = 1433
    database_name          = "master"
    application            = "Security Assessment"
    datasource_description = "SQL Server VA datasource"
    db_username            = "sqlguard"  # Use sqlguard for VA
    db_password            = var.sqlguard_password
    severity_level         = "MED"
    save_password          = true
    use_ssl                = false
    import_server_ssl_cert = false
    use_external_password  = false
    external_password_type_name    = ""
    aws_secrets_manager_config_name = ""
    region                 = ""
    secret_name            = ""
  })
}

# Step 3: Register with Guardium
module "mssql_gdp_connection" {
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = jsonencode(jsondecode(local.mssql_config))

  # Guardium credentials
  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username

  # VA Configuration
  datasource_name                 = "my-sqlserver-va"
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Monday"
  assessment_time                 = "02:00"

  # Notifications
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "HIGH"

  depends_on = [module.mssql_va_config]
}
```




## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| db_host | SQL Server database hostname | `string` | n/a | yes |
| db_port | SQL Server database port | `number` | `1433` | no |
| database_name | Database name | `string` | `"master"` | no |
| db_username | Database admin username (rdsadmin) | `string` | n/a | yes |
| db_password | Database admin password | `string` | n/a | yes |
| sqlguard_username | VA user username | `string` | `"sqlguard"` | no |
| sqlguard_password | VA user password | `string` | n/a | yes |
| vpc_id | VPC ID for Lambda deployment | `string` | n/a | yes |
| subnet_ids | Private subnet IDs for Lambda (with NAT gateway) | `list(string)` | n/a | yes |
| db_security_group_id | Security group ID of RDS SQL Server instance | `string` | n/a | yes |
| aws_region | AWS region | `string` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | ARN of the Secrets Manager secret |
| secret_name | Name of the Secrets Manager secret |
| lambda_function_name | Name of the Lambda function |
| lambda_log_group | CloudWatch log group for Lambda |
| db_host | SQL Server database host |
| db_port | SQL Server database port |
| sqlguard_username | VA user username (sqlguard) |

## Security Considerations

1. **Credentials Storage**: Both `rdsadmin` and `sqlguard` passwords are stored encrypted in AWS Secrets Manager
2. **Least Privilege**: `sqlguard` has only the permissions needed for VA scans:
   - Server-level VIEW permissions (VIEW SERVER STATE, VIEW ANY DEFINITION, VIEW ANY DATABASE)
   - setupadmin server role
   - gdmmonitor role in user databases (SELECT on system views)
3. **Separation of Duties**: `rdsadmin` for administration, `sqlguard` for VA scans only
4. **Network Security**: Lambda runs in private subnet with VPC endpoint for Secrets Manager
5. **Secrets Rotation**: Consider enabling automatic rotation for both secrets

## Troubleshooting

### Issue: Lambda function fails to create sqlguard user
**Solution**: Check Lambda logs:
```bash
aws logs tail /aws/lambda/<name-prefix>-mssql-va-config --follow
```
Common issues:
- Lambda cannot reach SQL Server (check security groups)
- Lambda cannot reach Secrets Manager (check VPC endpoint)
- rdsadmin credentials are incorrect
- SQL Server is not ready yet

### Issue: VA tests failing
**Solution**: Verify sqlguard user was created successfully:
```sql
-- Check server-level permissions
SELECT * FROM sys.server_permissions WHERE grantee_principal_id = SUSER_ID('sqlguard');

-- Check server role membership
SELECT IS_SRVROLEMEMBER('setupadmin', 'sqlguard');

-- Check database role membership (in user databases)
USE YourDatabase;
SELECT IS_ROLEMEMBER('gdmmonitor', 'sqlguard');
```




## Support

For issues and questions:
- Open an issue in the repository
- Contact IBM Guardium support
- Refer to IBM Guardium documentation

## References

- [IBM Guardium Documentation](https://www.ibm.com/docs/en/guardium)
- [AWS RDS SQL Server Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)