# Oracle Vulnerability Assessment Configuration Module

This module configures an AWS RDS Oracle or Oracle Autonomous Database for Guardium Vulnerability Assessment (VA). It creates the necessary `gdmmonitor` role and grants required permissions for Guardium to perform security assessments and entitlement reports.

## Features

- Creates a `gdmmonitor` role with necessary privileges
- Creates a VA user (e.g., `sqlguard`) and grants the `gdmmonitor` role
- Grants CONNECT and SELECT_CATALOG_ROLE privileges
- Grants READ permissions on system tables (DBA_USERS_WITH_DEFPWD, AUDIT_UNIFIED_POLICIES, etc.)
- Grants EXECUTE on password verification functions
- Uses AWS Lambda to execute PL/SQL commands within VPC
- Supports both RDS Oracle and Oracle Autonomous Database

## Prerequisites

- Oracle Database (RDS or Autonomous)
- Admin user with DBA privileges (or ADMIN for Autonomous)
- The database must be accessible from the Lambda function (VPC configuration required)
- VPC with subnets that have connectivity to the Oracle database

## Usage

### Basic Usage

```hcl
module "datastore-va_aws-oracle" {
  source = "IBM/datastore-va/guardium//modules/aws-oracle"

  name_prefix = "guardium"
  aws_region  = "us-east-1"

  # Oracle Connection Details
  db_host         = "your-oracle-db.xxxxx.us-east-1.rds.amazonaws.com"
  db_port         = 1521
  db_service_name = "ORCL"
  db_username     = "admin"
  db_password     = "your-password"

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

### Oracle Autonomous Database

```hcl
module "datastore-va_aws-oracle-autonomous" {
  source = "IBM/datastore-va/guardium//modules/aws-oracle"

  name_prefix = "guardium"
  aws_region  = "us-east-1"

  # Oracle Autonomous Connection Details
  db_host         = "your-autonomous-db.adb.us-east-1.oraclecloud.com"
  db_port         = 1522
  db_service_name = "your_service_high"
  db_username     = "ADMIN"
  db_password     = "your-admin-password"

  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"

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
- VPC and subnets with connectivity to Oracle database
- Oracle Instant Client libraries in Lambda layer (included in lambda_function.zip)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | n/a | yes |
| db_host | Hostname or IP address of the Oracle database | string | n/a | yes |
| db_port | Port for the Oracle database | number | 1521 | no |
| db_service_name | Service name of the Oracle database (e.g., ORCL, ORCLPDB1) | string | n/a | yes |
| db_username | Username for the Oracle database (must have DBA privileges or ADMIN for Autonomous) | string | n/a | yes |
| db_password | Password for the Oracle database | string | n/a | yes |
| sqlguard_username | Username for the Guardium VA user | string | "sqlguard" | no |
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
| secrets_manager_secret_arn | ARN of the Secrets Manager secret containing Oracle credentials |
| gdmmonitor_role_created | Confirmation message about gdmmonitor role creation |

## Notes

### Oracle-Specific Considerations

1. **Service Name**: Use the correct service name for your Oracle database:
   - RDS Oracle: Usually the database name (e.g., `ORCL`)
   - Autonomous: Service name with suffix (e.g., `mydb_high`, `mydb_medium`, `mydb_low`)

2. **Port**: 
   - RDS Oracle: Default is 1521
   - Autonomous: Usually 1522

3. **Admin User**:
   - RDS Oracle: User with DBA privileges
   - Autonomous: ADMIN user

4. **PL/SQL Script**: The module executes a comprehensive PL/SQL script that:
   - Creates the `gdmmonitor` role
   - Grants necessary system privileges
   - Grants READ on system tables
   - Grants EXECUTE on password verification functions
   - Preserves existing role members if the role already exists

### Lambda Function

The Lambda function requires:
- **cx_Oracle library**: Python driver for Oracle
- **Oracle Instant Client**: Oracle client libraries
- **Increased memory**: 512 MB (Oracle client requires more resources)
- **VPC configuration**: Must be able to reach the Oracle database

### Security Best Practices

1. **Credentials Management**:
   - Never commit sensitive credentials to version control
   - Use environment variables or AWS Secrets Manager
   - Rotate passwords regularly

2. **Network Security**:
   - Ensure Oracle security group allows connections from Lambda security group
   - Use private subnets for Lambda deployment
   - Enable VPC Flow Logs for network monitoring

3. **IAM Permissions**:
   - Follow principle of least privilege
   - Review and audit IAM policies regularly

### Troubleshooting

#### Lambda Function Fails

1. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/<function-name> --follow
   ```

2. Verify network connectivity:
   - Lambda security group allows outbound to Oracle port
   - Oracle security group allows inbound from Lambda security group
   - Subnets have route to NAT Gateway or VPC endpoints

3. Check Oracle Instant Client:
   - Ensure lambda_function.zip includes Oracle Instant Client libraries
   - Verify cx_Oracle is properly installed

#### Oracle Connection Fails

1. Verify service name is correct
2. Check Oracle listener is running
3. Verify credentials have DBA privileges
4. For Autonomous: Ensure wallet is configured (if required)

#### Role Creation Fails

1. Ensure admin user has sufficient privileges
2. Check Oracle database is not in restricted mode
3. Verify PL/SQL script syntax is compatible with Oracle version

## Building the Lambda Function

The Lambda function requires Oracle Instant Client and cx_Oracle. To build:

```bash
# Create a directory for the Lambda package
mkdir lambda_package
cd lambda_package

# Install cx_Oracle
pip install cx_Oracle -t .

# Download Oracle Instant Client (Basic Light)
# Extract to instantclient/ directory

# Add your Lambda function code (index.py)
# Create the zip file
zip -r ../lambda_function.zip .
```

**Note**: The lambda_function.zip file is not included in this repository due to size. You must build it with Oracle Instant Client libraries.

## Cleanup

To remove all resources created by this module:

```bash
terraform destroy
```

**Note**: This will:
- Delete the Lambda function and associated resources
- Remove the Secrets Manager secret (immediate deletion)
- **NOT** delete the Oracle database itself
- **NOT** remove the `gdmmonitor` role or `sqlguard` user from Oracle

To manually clean up Oracle objects:

```sql
DROP USER sqlguard CASCADE;
DROP ROLE gdmmonitor;
```

## Cost Considerations

This module incurs the following AWS costs:

- **Lambda**: Pay per invocation (one-time setup cost, minimal)
- **Secrets Manager**: ~$0.40/month per secret
- **VPC Endpoint**: ~$7.20/month for Secrets Manager endpoint
- **CloudWatch Logs**: Based on log retention and volume

## Support

For issues or questions:

1. Check the [main README](../../README.md) for general information
2. Review Oracle-specific documentation
3. Open an issue in the GitHub repository

## License

This module is provided under the same license as the main module.