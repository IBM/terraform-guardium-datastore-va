<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS SQL Server Vulnerability Assessment Example

This example demonstrates how to configure an AWS RDS SQL Server instance for IBM Guardium Vulnerability Assessment (VA).

## Overview

This module creates a dedicated `sqlguard` user with appropriate privileges for Guardium VA tests.

**Why create a separate user?**
- Security best practice: Separate credentials for VA scanning
- Audit trail: Distinguish VA activities from admin operations
- Credential rotation: Can rotate sqlguard password independently

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS RDS SQL Server                       │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  rdsadmin account (built-in admin)                 │    │
│  │  ✓ Used to create sqlguard user                    │    │
│  └────────────────────────────────────────────────────┘    │
│                           │                                  │
│                           │ Creates                          │
│                           ▼                                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │  sqlguard user (created by Lambda)                 │    │
│  │  ✓ Server-level VIEW permissions                   │    │
│  │  ✓ setupadmin server role                          │    │
│  │  ✓ gdmmonitor role in user databases               │    │
│  │  ✓ Used for Guardium VA scans                      │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ Lambda creates user
                            ▼
                ┌───────────────────────┐
                │  AWS Lambda Function  │
                │  (in VPC)             │
                │  - Connects as rdsadmin│
                │  - Creates sqlguard   │
                │  - Grants VIEW perms  │
                │  - Grants setupadmin  │
                │  - Creates gdmmonitor │
                └───────────────────────┘
                            │
                            │ Reads credentials
                            ▼
                ┌───────────────────────┐
                │  AWS Secrets Manager  │
                │  (stores both         │
                │   rdsadmin & sqlguard)│
                └───────────────────────┘
                            │
                            │ Guardium uses sqlguard
                            ▼
                ┌───────────────────────┐
                │  Guardium Server      │
                │  - Registers datasource│
                │  - Runs VA scans      │
                │  - Sends notifications│
                └───────────────────────┘
```

## Prerequisites

1. **AWS RDS SQL Server Instance**
   - Running and accessible
   - `rdsadmin` password available

2. **VPC Configuration**
   - VPC with private subnets
   - NAT Gateway configured (for Lambda to access Secrets Manager)
   - Security group allowing Lambda to connect to SQL Server on port 1433

3. **Guardium Server**
   - Accessible from your network
   - OAuth client configured
   - Admin credentials available

4. **Terraform**
   - Version >= 1.0.0
   - AWS Provider ~> 5.0
   - Guardium Data Protection Provider >= 1.0.0
   - GDP Middleware Helper Provider >= 1.0.0

## Quick Start

### 1. Clone and Navigate

```bash
cd examples/aws-rds-mss
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

**Required values:**
```hcl
# SQL Server (rdsadmin credentials - used to create sqlguard user)
db_host     = "your-sqlserver.region.rds.amazonaws.com"
db_username = "rdsadmin"
db_password = "your-rdsadmin-password"

# sqlguard user (will be created with VA-specific privileges)
sqlguard_username = "sqlguard"
sqlguard_password = "your-sqlguard-password"  # Choose a strong password

# VPC Configuration (where SQL Server is accessible)
vpc_id     = "vpc-xxxxxxxxx"
subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]  # Private subnets with NAT

# Guardium
gdp_server    = "your-guardium-server.com"
gdp_username  = "guardium_admin"
gdp_password  = "your-guardium-password"
client_secret = "your-oauth-client-secret"

# Notifications
notification_emails = ["security@example.com"]
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify

```bash
# Check outputs
terraform output

# Verify in Guardium UI:
# 1. Navigate to Data Sources
# 2. Find your datasource (default: "rds-mssql-va")
# 3. Check VA schedule is configured
# 4. Run a test scan
```

## What Gets Created

### AWS Resources
- ✅ **Secrets Manager Secret**: Stores both `rdsadmin` and `sqlguard` credentials securely
- ✅ **Lambda Function**: Creates sqlguard user with sysadmin privileges
- ✅ **IAM Role & Policy**: Permissions for Lambda to access Secrets Manager and VPC
- ✅ **Security Groups**: For Lambda and Secrets Manager VPC endpoint
- ✅ **VPC Endpoint**: Allows Lambda to access Secrets Manager from private subnet

### SQL Server Resources
- ✅ **sqlguard Login**: SQL Server login with server-level VIEW permissions
- ✅ **setupadmin Role**: Server role for additional access
- ✅ **gdmmonitor Role**: Custom role in user databases with SELECT on system views
- ✅ **sqlguard User**: Database user in each user database (member of gdmmonitor)

### Guardium Resources
- ✅ **Datasource Registration**: SQL Server registered with Guardium (using sqlguard credentials)
- ✅ **VA Schedule**: Automated vulnerability scans configured
- ✅ **Notifications**: Email alerts for findings

## Configuration Options

### Assessment Schedules

```hcl
# Daily at 2 AM
assessment_schedule = "daily"
assessment_time     = "02:00"

# Weekly on Monday at 2 AM
assessment_schedule = "weekly"
assessment_day      = "Monday"
assessment_time     = "02:00"

# Monthly on the 1st at 2 AM
assessment_schedule = "monthly"
assessment_day      = "1"
assessment_time     = "02:00"
```

### Notification Levels

```hcl
notification_severity = "HIGH"  # Only critical findings
notification_severity = "MED"   # Medium and above
notification_severity = "LOW"   # All findings
```

### SSL Configuration

```hcl
use_ssl                = true
import_server_ssl_cert = true
```

## Network Configuration

### Security Group Requirements

**IMPORTANT**: Your SQL Server instance must allow inbound connections from the Guardium server.

#### Step 1: Get Guardium Server IP

```bash
# Method 1: SSH to Guardium and get public IP (RECOMMENDED)
ssh admin@your-guardium-server.com
curl ifconfig.me
# This returns the public IP that AWS will see

# Method 2: Get private IP (if in same VPC)
ssh admin@your-guardium-server.com
hostname -I

# Method 3: DNS lookup
nslookup your-guardium-server.com
# or
dig +short your-guardium-server.com
```

**Important**: Use the IP returned by `curl ifconfig.me` as this is the public IP that will connect to your RDS instance.

#### Step 2: Update Security Group

Add an inbound rule to your SQL Server's security group:

**Option A: Using AWS CLI**

```bash
# First, get your RDS instance's security group ID
aws rds describe-db-instances \
  --db-instance-identifier your-sqlserver-instance \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text

# Then add the inbound rule (replace with your values)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 1433 \
  --cidr <GUARDIUM_IP>/32 \
  --description "Allow Guardium VA access"

```

**Option B: Using Terraform**

```hcl
# Add to your Terraform configuration
resource "aws_security_group_rule" "guardium_access" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = ["<GUARDIUM_IP>/32"]  # Replace with actual IP
  security_group_id = aws_db_instance.sqlserver.vpc_security_group_ids[0]
  description       = "Allow Guardium VA access"
}
```

**Option C: Using AWS Console**

1. Go to **EC2 → Security Groups**
2. Find your SQL Server's security group
3. Click **Edit inbound rules**
4. Add rule:
   - Type: `MSSQL/Aurora (1433)`
   - Source: `Custom` → `<GUARDIUM_IP>/32`
   - Description: `Guardium VA access`
5. Save rules

#### Step 3: Verify Connectivity

```bash
# From Guardium server, test connection
telnet your-sqlserver.rds.amazonaws.com 1433

# Or use sqlcmd
sqlcmd -S your-sqlserver.rds.amazonaws.com -U admin -P your-password
```

### Network Topology Considerations

- **Same VPC**: Use Guardium's private IP
- **Different VPC**: Set up VPC peering or use public IP (if available)
- **Different Region**: Use VPC peering or Transit Gateway
- **On-Premises Guardium**: Use VPN or Direct Connect

## Troubleshooting

### Issue: Terraform init fails
```bash
# Solution: Ensure Guardium provider is configured
terraform {
  required_providers {
    guardium-data-protection = {
      source  = "IBM/guardium-data-protection"
      version = ">= 1.0.0"
    }
  }
}
```

### Issue: Cannot connect to SQL Server
```bash
# Check connectivity
telnet your-sqlserver.rds.amazonaws.com 1433

# Verify credentials
sqlcmd -S your-sqlserver.rds.amazonaws.com -U rdsadmin -P your-password
```

### Issue: Lambda function fails to create sqlguard user
```bash
# Check Lambda logs
aws logs tail /aws/lambda/mssql-va-sqlguard-creator --follow

# Common issues:
# 1. Lambda cannot reach SQL Server (VPC/Security Group)
# 2. Lambda cannot reach Secrets Manager (VPC endpoint missing)
# 3. rdsadmin credentials are incorrect
# 4. SQL Server is not ready yet

# Verify Lambda can reach SQL Server
# Check Lambda security group allows outbound to SQL Server port 1433
# Check SQL Server security group allows inbound from Lambda security group

# Verify VPC endpoint for Secrets Manager exists
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<your-vpc-id>"
```

### Issue: VA tests failing
- Verify `sqlguard` password is correct in Secrets Manager
- Verify `sqlguard` user was created successfully (check Lambda logs)
- Check SQL Server version is supported
- Review Guardium logs for specific errors
- Ensure database is online
- Verify sqlguard has correct permissions:
  ```sql
  -- Check server-level permissions
  SELECT * FROM sys.server_permissions WHERE grantee_principal_id = SUSER_ID('sqlguard');
  
  -- Check server role membership
  SELECT IS_SRVROLEMEMBER('setupadmin', 'sqlguard');
  
  -- Check database role membership (in user databases)
  USE YourDatabase;
  SELECT IS_ROLEMEMBER('gdmmonitor', 'sqlguard');
  ```

### Issue: No notifications received
- Verify email addresses in `notification_emails`
- Check notification severity threshold
- Confirm SMTP is configured in Guardium
- Review Guardium notification settings

## Outputs

After successful deployment:

```bash
terraform output

# Example output:
rdsadmin_secret_arn                 = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rdsadmin-..."
sqlguard_secret_arn                 = "arn:aws:secretsmanager:us-east-1:123456789012:secret:sqlguard-..."
lambda_function_name                = "mssql-va-sqlguard-creator"
lambda_log_group                    = "/aws/lambda/mssql-va-sqlguard-creator"
mssql_instance_address              = "my-sqlserver.abc123.us-east-1.rds.amazonaws.com"
mssql_instance_port                 = 1433
mssql_instance_username             = "sqlguard"  # Note: Using sqlguard, not rdsadmin
datasource_name                     = "my-sqlserver-va"
gdp_server                          = "guardium.example.com"
gdp_vulnerability_assessment_enabled = true
gdp_assessment_schedule             = "weekly"
va_config_status                    = "Completed"
```

## Cleanup

```bash
# Remove all resources
terraform destroy

# Confirm when prompted
```

## Cost Estimate

**AWS Costs (Monthly):**
- Secrets Manager: ~$0.40/secret × 2 (rdsadmin + sqlguard) = ~$0.80
- Lambda: Free tier covers 1M requests/month (minimal usage)
- VPC Endpoint: ~$7.30/month (Secrets Manager endpoint)
- CloudWatch Logs: ~$0.50/GB ingested (Lambda logs)
- **Total: ~$8.60/month**

## Security Best Practices

1. **Rotate Credentials**: Enable automatic rotation for both rdsadmin and sqlguard secrets
2. **Least Privilege**: `sqlguard` has only the permissions needed for VA scans:
   - Server-level VIEW permissions (VIEW SERVER STATE, VIEW ANY DEFINITION, VIEW ANY DATABASE)
   - setupadmin server role
   - gdmmonitor role in user databases (SELECT on system views)
3. **Network Security**: 
   - Use security groups to restrict database access
   - Lambda runs in private subnet with no internet access
   - VPC endpoint for secure Secrets Manager access
4. **Audit Logs**: 
   - Enable CloudTrail for Secrets Manager access
   - Lambda logs all user creation activities
5. **Encryption**: 
   - Secrets Manager encrypts data at rest by default
   - Use KMS for additional key management
6. **Separation of Duties**: 
   - `rdsadmin` for database administration
   - `sqlguard` dedicated for Guardium VA scans only

## Next Steps

1. **Review VA Results**: Check Guardium dashboard for findings
2. **Tune Notifications**: Adjust severity thresholds as needed
3. **Schedule Maintenance**: Plan remediation for identified issues
4. **Monitor Trends**: Track vulnerability trends over time
5. **Automate Remediation**: Consider automated fixes for common issues

## Support

- **Documentation**: [IBM Guardium Docs](https://www.ibm.com/docs/en/guardium)
- **Issues**: Open an issue in the repository
- **Questions**: Contact IBM Guardium support

