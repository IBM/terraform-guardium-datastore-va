<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS SQL Server Vulnerability Assessment Example

This example demonstrates how to configure an AWS RDS SQL Server instance for IBM Guardium Vulnerability Assessment (VA).

## Overview

AWS RDS SQL Server's built-in `rdsadmin` account already has all necessary privileges for Guardium VA tests. 

Simply provide the `rdsadmin` credentials and register with Guardium!

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS RDS SQL Server                       │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  rdsadmin account (built-in)                       │    │
│  │  ✓ Has all VA privileges by default                │    │
│  │  ✓ No additional setup needed                      │    │
│  └────────────────────────────────────────────────────┘    │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            │ Direct connection
                            │ (no Lambda needed)
                            ▼
                ┌───────────────────────┐
                │  AWS Secrets Manager  │
                │  (stores rdsadmin     │
                │   password securely)  │
                └───────────────────────┘
                            │
                            │
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

2. **Guardium Server**
   - Accessible from your network
   - OAuth client configured
   - Admin credentials available

3. **Terraform**
   - Version >= 1.0.0
   - AWS Provider ~> 5.0
   - Guardium Data Protection Provider >= 1.0.0

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
# SQL Server
db_host     = "your-sqlserver.region.rds.amazonaws.com"
db_password = "your-rdsadmin-password"

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
- ✅ **Secrets Manager Secret**: Stores `rdsadmin` credentials securely
- ✅ **Secret Version**: Contains encrypted password

### Guardium Resources
- ✅ **Datasource Registration**: SQL Server registered with Guardium
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

### Issue: VA tests failing
- Verify `rdsadmin` password is correct
- Check SQL Server version is supported
- Review Guardium logs for specific errors
- Ensure database is online

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
secret_arn                          = "arn:aws:secretsmanager:us-east-1:123456789012:secret:..."
secret_name                         = "my-app-mssql-va-mssql-rds-va-credentials"
mssql_instance_address              = "my-sqlserver.abc123.us-east-1.rds.amazonaws.com"
mssql_instance_port                 = 1433
mssql_instance_username             = "rdsadmin"
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
- Secrets Manager: ~$0.40/secret + $0.05 per 10,000 API calls
- **Total: ~$0.50/month**

## Security Best Practices

1. **Rotate Credentials**: Enable automatic rotation for Secrets Manager
2. **Least Privilege**: `rdsadmin` has appropriate permissions by default
3. **Network Security**: Use security groups to restrict database access
4. **Audit Logs**: Enable CloudTrail for Secrets Manager access
5. **Encryption**: Secrets Manager encrypts data at rest by default

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

