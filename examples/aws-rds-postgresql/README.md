# AWS RDS PostgreSQL with Vulnerability Assessment - Quick Start Guide

This guide helps you set up vulnerability assessment for AWS RDS PostgreSQL using IBM Guardium Data Protection. Follow the steps in order for a smooth setup.

> **🔒 Security Note:** SSL/TLS encryption is enabled by default for all database connections (Lambda and Guardium).

---

## 🏗️ What This Example Does

This Terraform configuration:
- **Configures a PostgreSQL database** for Vulnerability Assessment by creating a dedicated `sqlguard` user with appropriate permissions
- **Connects the PostgreSQL database** to Guardium Data Protection (GDP) for vulnerability scanning
- **Enables SSL/TLS encryption** by default for all database connections (Lambda and Guardium)
- **Enables vulnerability assessments** for automated security scanning

### Architecture Overview

```
┌─────────────────┐          ┌─────────────────┐
│                 │          │                 │
│  AWS RDS        │◄────────►│  AWS Lambda     │
│  PostgreSQL     │          │  (VA Config)    │
│                 │          │                 │
└────────┬────────┘          └────────┬────────┘
         │                            │
         │                            │
         │                            │
         ▼                            ▼
┌─────────────────┐          ┌─────────────────┐
│                 │          │                 │
│  Guardium Data  │◄────────►│  Vulnerability  │
│  Protection     │          │  Assessment     │
│                 │          │                 │
└─────────────────┘          └─────────────────┘
```

### How It Works (Data Flow)

1. **VA Configuration** - Creates a Lambda function that connects to your PostgreSQL database, creates a dedicated `sqlguard` user with appropriate permissions, and sets up the necessary database configuration for vulnerability assessment
2. **GDP Connection** - Registers the PostgreSQL database as a data source in Guardium and enables vulnerability assessment
3. **Assessment Execution** - Guardium performs vulnerability assessments and results are available in the Guardium console

### What Gets Scanned?

Guardium vulnerability assessment checks for:
- ✅ **Security configuration** - Weak or default passwords, excessive user privileges, public accessibility settings, unencrypted connections, authentication methods
- ✅ **Database configuration** - PostgreSQL version and patch level, deprecated features in use, insecure configuration parameters, missing security extensions, audit logging settings
- ✅ **Access control** - Overprivileged users, unused accounts, shared accounts, missing role-based access controls, superuser usage
- ✅ **Compliance checks** - CIS PostgreSQL Benchmark, PCI-DSS requirements, HIPAA compliance, GDPR data protection, SOC 2 controls

---

## 📦 Modules Used

This example uses two Terraform modules:

### 1. `aws-rds-postgresql` Module (Local)
**Location:** `../../modules/aws-rds-postgresql`

**What it does:**
- Deploys a Lambda function in your VPC
- Creates the `sqlguard` user in PostgreSQL
- Configures database permissions for VA
- Sets up security groups for Lambda access
- Stores credentials in AWS Secrets Manager

**Resources created:**
- `aws_lambda_function` - Lambda for database configuration
- `aws_iam_role` - IAM role for Lambda execution
- `aws_iam_policy` - Policies for Lambda permissions
- `aws_security_group` - Security group for Lambda
- `aws_secretsmanager_secret` - Stores sqlguard credentials

### 2. `connect-datasource-to-va` Module (Remote)
**Location:** `IBM/gdp/guardium//modules/connect-datasource-to-va`

**What it does:**
- Registers PostgreSQL as a datasource in Guardium
- Enables vulnerability assessment
- Manages SSL certificate import
- Handles OAuth authentication

**Resources created:**
- Guardium datasource registration
- Vulnerability assessment configuration
- SSL certificate import

---


## 📋 What You'll Need (Prerequisites)

Before starting, make sure you have:

- ✅ An existing AWS RDS PostgreSQL database
- ✅ VPC and subnet information where the database is deployed
- ✅ Appropriate IAM permissions to create Lambda functions and Secrets Manager resources
- ✅ Access to a Guardium Data Protection instance
- ✅ Admin credentials for the GDP instance
- ✅ OAuth client credentials (generated using `grdapi register_oauth_client`)
- ✅ SSH access to the GDP instance (for file operations)
- ✅ Terraform installed (version >= 1.0.0)
- ✅ AWS CLI configured

---

## 🚀 Step-by-Step Setup

### Step 1: Verify Your AWS Access

First, make sure your AWS credentials are working:

```bash
aws sts get-caller-identity
```

You should see your AWS account ID and user information. If not, configure your credentials:

```bash
aws configure
```

---

### Step 2: Gather AWS Information

You'll need several pieces of information from your AWS environment.

#### 2.1 Get Your RDS Endpoint

```bash
aws rds describe-db-instances \
  --db-instance-identifier your-db-name \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

#### 2.2 Get Your VPC and Subnet Information

```bash
# Get VPC ID
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# Get subnet IDs in your VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone]' \
  --output table
```

#### 2.3 Get Your Database Security Group

```bash
aws rds describe-db-instances \
  --db-instance-identifier your-db-name \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
  --output text
```

---

### Step 3: Get Your Guardium OAuth Credentials

You need OAuth credentials to connect Terraform to Guardium:

1. SSH into your Guardium server:
   ```bash
   ssh cli@your-guardium-server.com
   ```

2. Run this command to generate OAuth credentials:
   ```bash
   grdapi register_oauth_client client_id=client1 grant_types=password
   ```

3. **Save the output** - you'll need the `client_secret` value in the next step

---

### Step 4: Configure Your Variables

Copy the example file and edit it with your values:

```bash
cd examples/aws-rds-postgresql
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

Now fill in these values:

#### 🔧 Required Settings (You MUST change these)

```hcl
# AWS Configuration
aws_region = "us-west-2"  # Your AWS region

# Database Connection
db_host     = "mydb.abc123.us-west-2.rds.amazonaws.com"  # ← From Step 2.1
db_name     = "guardiumdb"                                # ← Your database name
db_username = "guardium_admin"                            # ← Master username
db_password = "YourStrongPasswordHere"                    # ← Master password

# VA User Credentials
sqlguard_username = "sqlguard"                            # ← VA user to create
sqlguard_password = "YourStrongPasswordHere"              # ← Create a strong password

# Network Configuration
vpc_id               = "vpc id where the db is deployed"  # ← From Step 2.2
subnet_ids           = ["subnet-1", "subnet-2"]           # ← From Step 2.2
db_security_group_id = "sg-xxxxxxxxx"                     # ← From Step 2.3

# Guardium Server Details
gdp_server   = "your-guardium-server.example.com"  # ← Your Guardium hostname
gdp_port     = "8443"                               # ← Guardium API port
gdp_username = "admin"                   # ← Your Guardium username
gdp_password = "password"                # ← Your Guardium password
client_id    = "client2"                 # ← From Step 3
client_secret = "12345"                  # ← From Step 3 output
```

#### ⚙️ Optional Settings (You can customize these)

```hcl
# Resource Naming
name_prefix = "prefix-for-aws-resources"  # Prefix for AWS resource names

# Database Port (only change if you modified the default)
db_port = 5432

# PostgreSQL Datasource Details
datasource_name        = "rds-postgresql-va"  # Name shown in Guardium
datasource_description = "PostgreSQL data source onboarded via Terraform"

# Application Type (what this datasource is used for)
# Options: "Security Assessment", "Audit Task", "Compliance"
application = "Security Assessment"

# Severity Level (how critical is this datasource)
# Options: "LOW", "NONE", "MED", "HIGH"
severity_level = "MED"

# Vulnerability Assessment
enable_vulnerability_assessment = true

# SSL/TLS (Recommended: keep these as true)
use_ssl                = true
import_server_ssl_cert = true

# AWS Resource Tags
tags = {
  Purpose     = "guardium-va-config"
  Owner       = "example@ibm.com"
  Environment = "dev"
  Project     = "guardium-terraform"
}
```

---

### Step 5: Run Terraform

Now you're ready to deploy!

#### 5.1 Initialize Terraform
```bash
terraform init
```

#### 5.2 Preview What Will Be Created
```bash
terraform plan
```

Review the output to see what resources will be created.

#### 5.3 Apply the Configuration
```bash
terraform apply
```

Type `yes` when prompted to confirm.

---

## ✅ What Gets Created

This Terraform configuration will:

1. **Create Lambda Function** - Deploys a Lambda in your VPC to configure PostgreSQL
2. **Create IAM Role & Policies** - Allows Lambda to access PostgreSQL and Secrets Manager
3. **Create Security Group Rules** - Allows Lambda to connect to PostgreSQL on port 5432
4. **Create `sqlguard` User** - Lambda creates this user in PostgreSQL with read-only permissions
5. **Store Credentials** - Saves sqlguard credentials in AWS Secrets Manager
6. **Register Datasource in Guardium** - Adds PostgreSQL as a monitored datasource
7. **Configure Vulnerability Assessment** - Sets up automated security scans

---

## 📊 View Your Results

After successful deployment:

1. Log into your Guardium Data Protection console
2. Navigate to **Data Sources** to see your registered PostgreSQL datasource
3. Verify the status shows "Connected"
4. Go to **Vulnerability Assessment** to view scan results

---

## 🔍 Understanding the Variables

### What is `application`?
This categorizes what the datasource is used for:
- **"Security Assessment"** - For vulnerability scanning (most common)
- **"Audit Task"** - For compliance auditing
- **"Compliance"** - For regulatory compliance monitoring

### What is `severity_level`?
This indicates how critical this datasource is:
- **"LOW"** - Development/test environments
- **"NONE"** - Non-sensitive data
- **"MED"** - Staging or non-critical production
- **"HIGH"** - Critical production systems with sensitive data

### Why do I need two passwords?
- **`db_password`** - Master password for your RDS database. Lambda uses this to create the sqlguard user.
- **`sqlguard_password`** - Password for the VA user. Guardium uses this for scanning.

This separation follows security best practices - Guardium never needs your master credentials.

---

## 🛠️ Troubleshooting

### Problem: "Lambda cannot connect to database"
**Solution:** 
- Check security group rules: `aws ec2 describe-security-groups --group-ids sg-xxxxx`
- Ensure inbound rule allows traffic from Lambda security group on port 5432
- Verify Lambda subnets have route to database subnets
- Test connectivity from a bastion host: `telnet your-db-endpoint.rds.amazonaws.com 5432`

### Problem: "Authentication failed for user"
**Solution:**
- Verify db_username and db_password in terraform.tfvars
- Check for typos or extra spaces
- Verify RDS master user: `aws rds describe-db-instances --db-instance-identifier your-db-name --query 'DBInstances[0].MasterUsername'`
- Reset password if needed via AWS Console

### Problem: "Guardium connection failed"
**Solution:**
- Test network connectivity: `curl -k https://your-guardium-server:8443`
- Verify OAuth credentials: SSH to Guardium and run `grdapi list_oauth_clients`
- Check gdp_username and gdp_password are correct
- Ensure Guardium user has admin privileges

### Problem: "SSL certificate import failed"
**Solution:**
- Verify `use_ssl = true` and `import_server_ssl_cert = true`
- Check Guardium logs: `ssh cli@guardium-server` then `tail -f /var/log/guardium/va.log`

### Problem: "Assessment not running"
**Solution:**
- Check data source status in Guardium console (should show "Connected")
- Run manual assessment: Guardium → Vulnerability Assessment → Run Assessment Now
- Check for error messages in Guardium logs

### Check Lambda Logs
```bash
# View Lambda execution logs
aws logs tail /aws/lambda/your-function-name --follow

# Check Lambda function details
aws lambda get-function --function-name your-function-name
```

---

## 🔐 Security Best Practices

1. **Never commit `terraform.tfvars` to version control** - It contains sensitive passwords
2. **Use strong passwords** - Minimum 12 characters with mixed case, numbers, and symbols
3. **Rotate credentials regularly** - Change passwords every 90 days
4. **Use least privilege** - Only grant necessary IAM permissions
5. **Enable SSL/TLS** - Keep `use_ssl = true` (default)
6. **Deploy Lambda in private subnets** - Never use public subnets
7. **Review findings regularly** - Check vulnerability assessment reports weekly

---

## 📚 Additional Resources

- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [AWS RDS PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🆘 Need Help?

- Check the [Troubleshooting](#-troubleshooting) section above
- Review Terraform logs: `terraform apply` output
- Check Lambda CloudWatch logs for detailed error messages
- Contact your Guardium administrator
- Open an issue in the GitHub repository

---

## 📝 Quick Reference: All Variables

| Variable | Required? | Default | Description |
|----------|-----------|---------|-------------|
| `aws_region` | No | `us-east-1` | AWS region where resources will be created |
| `name_prefix` | No | `rds-postgresql-monitoring` | Prefix for AWS resource names |
| `db_host` | **Yes** | - | RDS PostgreSQL endpoint |
| `db_port` | No | `5432` | PostgreSQL port |
| `db_name` | **Yes** | - | Database name to connect to |
| `db_username` | No | `guardium_admin` | Master username for database |
| `db_password` | **Yes** | - | Master password for database |
| `sqlguard_username` | No | `sqlguard` | Username for VA user |
| `sqlguard_password` | **Yes** | - | Password for VA user |
| `vpc_id` | **Yes** | - | VPC ID where database is deployed |
| `subnet_ids` | **Yes** | - | List of subnet IDs for Lambda |
| `db_security_group_id` | **Yes** | - | Security group ID of PostgreSQL database |
| `gdp_server` | **Yes** | - | Guardium server hostname or IP |
| `gdp_port` | No | `8443` | Guardium API port |
| `gdp_username` | **Yes** | - | Guardium admin username |
| `gdp_password` | **Yes** | - | Guardium admin password |
| `client_id` | No | `client1` | OAuth client ID |
| `client_secret` | **Yes** | - | OAuth client secret from grdapi command |
| `datasource_name` | No | `rds-postgresql-va` | Display name in Guardium |
| `datasource_description` | No | `PostgreSQL data source...` | Description in Guardium |
| `application` | No | `Security Assessment` | Datasource category |
| `severity_level` | No | `MED` | Criticality level (LOW/NONE/MED/HIGH) |
| `enable_vulnerability_assessment` | No | `true` | Enable VA scans |
| `use_ssl` | No | `true` | Enable SSL/TLS encryption |
| `import_server_ssl_cert` | No | `true` | Auto-import AWS RDS CA certificate |
| `tags` | No | `{}` | AWS resource tags |
