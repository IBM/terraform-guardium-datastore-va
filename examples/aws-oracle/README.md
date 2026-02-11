# AWS Oracle with Guardium Vulnerability Assessment

This example demonstrates how to configure AWS RDS Oracle or Oracle Autonomous Database for Guardium Vulnerability Assessment and connect it to Guardium Data Protection.

## Overview

This Terraform configuration automates the complete setup process:

1. Creates a Lambda function that configures Oracle database for vulnerability assessment
2. Creates the `sqlguard` user with necessary privileges for Guardium VA scans
3. Registers the database with Guardium Data Protection
4. Configures vulnerability assessment schedules and notifications
5. **SSL/TLS encryption is enabled by default** for all database connections (Lambda and Guardium)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC                                    │  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │  Lambda Function│────────▶│  Oracle Database     │   │  │
│  │  │  (VA Config)    │         │  (RDS/Autonomous)    │   │  │
│  │  │  + cx_Oracle    │         │                      │   │  │
│  │  └────────┬────────┘         └──────────────────────┘   │  │
│  │           │                                              │  │
│  │  ┌────────▼────────┐         ┌──────────────────────┐   │  │
│  │  │  Secrets Manager│         │  VPC Endpoint        │   │  │
│  │  │  (Credentials)  │◀────────│  (Secrets Manager)   │   │  │
│  │  └─────────────────┘         └──────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
                    ┌──────────────────┐
                    │   Guardium Data  │
                    │   Protection     │
                    └──────────────────┘
```

## Prerequisites

### 1. Oracle Database
- Existing AWS RDS Oracle or Oracle Autonomous Database
- Admin user with DBA privileges (or ADMIN for Autonomous)
- Database accessible from VPC subnets

### 2. AWS Infrastructure
- VPC with private subnets
- Subnets with connectivity to Oracle database
- Security groups configured to allow Lambda → Oracle communication (port 1521 or 1522)

### 3. Guardium Data Protection
- Guardium server accessible from your network
- Admin credentials
- OAuth client credentials (generate using: `grdapi register_oauth_client client_id=client1 grant_types=password`)

### 4. Tools
- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- AWS provider >= 5.0

### 5. Lambda Function Package
**IMPORTANT**: You must build the Lambda deployment package with Oracle Instant Client before running Terraform. See "Building the Lambda Function" below.

## Building the Lambda Function

The Lambda function requires Oracle Instant Client and cx_Oracle. Build the package before deploying:

```bash
# Navigate to the module directory
cd ../../modules/aws-oracle/files

# Run the build script (creates lambda_function.zip)
./build_lambda.sh
```

Or build manually:

```bash
cd ../../modules/aws-oracle/files
mkdir -p lambda_build && cd lambda_build

# Install cx_Oracle for Lambda
pip install cx_Oracle -t . --platform manylinux2014_x86_64 --only-binary=:all:

# Download Oracle Instant Client Basic Light
wget https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basiclite-linux.x64-19.23.0.0.0dbru.zip
unzip instantclient-basiclite-linux.x64-19.23.0.0.0dbru.zip
mv instantclient_19_23 instantclient

# Copy Lambda handler and SQL script
cp ../index.py .
cp ../scripts/oracle-va-config.sql .

# Create deployment package
zip -r ../lambda_function.zip . -x "*.zip"
cd .. && rm -rf lambda_build
```

## Quick Start

### Step 1: Get Oracle Database Information

Find your Oracle database details:

```bash
# Get database endpoint, port, and network configuration
aws rds describe-db-instances \
  --db-instance-identifier your-db-instance-id \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,VpcId:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName}' \
  --output json

# Get subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name your-subnet-group-name \
  --query 'DBSubnetGroups[0].Subnets[*].SubnetIdentifier' \
  --output json
```

### Step 2: Configure Variables

Copy and edit the configuration file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values. Here are the **essential** variables you must configure:

```hcl
# Oracle Configuration
db_host         = "your-oracle-db.xxxxx.us-east-1.rds.amazonaws.com"
db_port         = 1521
db_service_name = "ORCL"  # or ORCLPDB1, or mydb_high for Autonomous
db_username     = "admin"
db_password     = "your-secure-password"

# Network Configuration
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "your-guardium-password"
client_secret = "your-client-secret"

# VA User Configuration
sqlguard_password = "your-sqlguard-password"
```

**Note**: The `terraform.tfvars.example` file contains additional optional variables for:
- Datasource registration (name, description, application type, severity)
- Vulnerability assessment scheduling (schedule, day, time)
- Notification configuration (emails, severity threshold)

See the full example file for all available configuration options.

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 4: Verify

After deployment, verify the setup:

1. **Check Lambda execution** in CloudWatch Logs
2. **Verify Oracle objects**:
   ```sql
   SELECT USERNAME FROM DBA_USERS WHERE USERNAME = 'SQLGUARD';
   SELECT ROLE FROM DBA_ROLES WHERE ROLE = 'GDMMONITOR';
   SELECT GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE = 'SQLGUARD';
   ```
3. **Confirm Guardium registration** in the Guardium console
4. **Check VA schedule** is configured

## What Gets Created

### AWS Resources
- Lambda function with Oracle Instant Client (512 MB memory)
- IAM role and policy for Lambda
- Security groups for Lambda and VPC endpoint
- Secrets Manager secret for credentials
- VPC endpoint for Secrets Manager

### Oracle Database Objects
- `sqlguard` user with necessary VA privileges
- System privileges and READ permissions on required tables

### Guardium Configuration
- Datasource registration
- Vulnerability assessment schedule
- Email notifications

## Important Notes

### Oracle-Specific Configuration

**Service Name:**
- RDS Oracle: Database name (e.g., `ORCL`, `ORCLPDB1`)
- Autonomous: Service with suffix (e.g., `mydb_high`, `mydb_medium`, `mydb_low`)

**Port:**
- RDS Oracle: 1521 (default)
- Autonomous: 1522 (typical)

**Admin User:**
- RDS Oracle: User with DBA privileges
- Autonomous: ADMIN user

### Security Best Practices

1. **Never commit `terraform.tfvars`** to version control
2. **Use environment variables** for sensitive values
3. **Rotate passwords regularly**
4. **Use private subnets** for Lambda
5. **Restrict security group** access to Lambda only

## Troubleshooting

### Lambda Function Fails

Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/<function-name> --follow
```

Common issues:
- **Oracle Instant Client not found**: Verify Lambda package was built correctly
- **Connection timeout**: Check security groups and network connectivity
- **Authentication failed**: Verify credentials and DBA privileges

### Terraform State Issues

If you encounter "resource already exists" errors:

```bash
# Import existing security group
terraform import module.oracle_va_config.aws_security_group.lambda_sg sg-xxxxx

# Import security group rule
terraform import 'module.oracle_va_config.aws_security_group_rule.lambda_to_oracle[0]' \
  sg-xxxxx_ingress_tcp_1521_1521_sg-yyyyy
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```

**Note**: This removes AWS resources but does NOT delete:
- The Oracle database itself
- The `sqlguard` user created in Oracle

To manually clean up the Oracle user:
```sql
DROP USER sqlguard CASCADE;
```

## Cost Estimate

Monthly AWS costs (approximate):
- Lambda: ~$0.01 (one-time execution)
- Secrets Manager: ~$0.40/month
- VPC Endpoint: ~$7.20/month
- CloudWatch Logs: Minimal
## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region where resources will be created | `string` | `"us-east-1"` | no |
| name_prefix | Prefix for resource names | `string` | `"oracle-monitoring"` | no |
| db_host | Oracle database hostname or endpoint | `string` | n/a | yes |
| db_port | Oracle database port | `number` | `1521` | no |
| db_service_name | Oracle service name | `string` | n/a | yes |
| db_username | Oracle admin username | `string` | n/a | yes |
| db_password | Oracle admin password | `string` | n/a | yes |
| vpc_id | VPC ID where Lambda will be deployed | `string` | n/a | yes |
| subnet_ids | Subnet IDs for Lambda deployment | `list(string)` | n/a | yes |
| sqlguard_username | Guardium VA user to be created | `string` | `"sqlguard"` | no |
| sqlguard_password | Password for sqlguard user | `string` | n/a | yes |
| gdp_server | Guardium Data Protection server hostname | `string` | n/a | yes |
| gdp_port | Guardium server port | `string` | `"8443"` | no |
| gdp_username | Guardium admin username | `string` | n/a | yes |
| gdp_password | Guardium admin password | `string` | n/a | yes |
| client_id | OAuth client ID | `string` | `"client1"` | no |
| client_secret | OAuth client secret | `string` | n/a | yes |
| datasource_name | Name for datasource in Guardium | `string` | `"oracle-production"` | no |
| datasource_description | Description for datasource | `string` | `"Oracle production database onboarded via Terraform"` | no |
| application | Application type | `string` | `"Security Assessment"` | no |
| severity_level | Severity level (LOW, NONE, MED, HIGH) | `string` | `"MED"` | no |
| enable_vulnerability_assessment | Enable vulnerability assessment | `bool` | `true` | no |
| assessment_schedule | Assessment schedule (daily, weekly, monthly) | `string` | `"weekly"` | no |
| assessment_day | Day to run assessment | `string` | `"Monday"` | no |
| assessment_time | Time to run assessment (HH:MM) | `string` | `"02:00"` | no |
| enable_notifications | Enable email notifications | `bool` | `true` | no |
| notification_emails | Email addresses for notifications | `list(string)` | `[]` | no |
| notification_severity | Minimum severity for notifications | `string` | `"HIGH"` | no |
| use_ssl | Enable SSL/TLS for Guardium connections | `bool` | `true` | no |
| import_server_ssl_cert | Import AWS server SSL certificate automatically | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |


## Support

- [Main README](../../README.md)
- [Module Documentation](../../modules/aws-oracle/README.md)
- [GitHub Issues](https://github.com/IBM/terraform-guardium-datastore-va/issues)

## License

Apache 2.0 - See [LICENSE](../../LICENSE) for details.