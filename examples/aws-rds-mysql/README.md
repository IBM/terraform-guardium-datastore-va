# AWS RDS MySQL with Vulnerability Assessment - Quick Start Guide

This guide helps you set up vulnerability assessment for AWS RDS MySQL using IBM Guardium Data Protection. Follow the steps in order for a smooth setup.

> **🔒 Security Note:** SSL/TLS encryption is enabled by default for all database connections (Lambda and Guardium).

---

## 🏗️ What This Example Does

This Terraform configuration:
- **Creates a Lambda function** that configures your MySQL database for vulnerability scanning
- **Creates a dedicated `sqlguard` user** with read-only permissions for security assessments
- **Registers MySQL as a datasource** in Guardium Data Protection
- **Configures vulnerability assessment** to automatically scan for security issues

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC                                    │  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │  Lambda Function│────────▶│  RDS MySQL           │   │  │
│  │  │  (VA Config)    │         │  Instance            │   │  │
│  │  └────────┬────────┘         └──────────────────────┘   │  │
│  │           │                                              │  │
│  │           │                                              │  │
│  │  ┌────────▼────────┐         ┌──────────────────────┐   │  │
│  │  │  Secrets Manager│         │  VPC Endpoint        │   │  │
│  │  │  (Credentials)  │◀────────│  (Secrets Manager)   │   │  │
│  │  └─────────────────┘         └──────────────────────┘   │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
                    ┌──────────────────┐
                    │   Guardium Data  │
                    │   Protection     │
                    │   (GDP)          │
                    └──────────────────┘
```

### How It Works (Data Flow)

1. **Lambda configures MySQL** - Creates the `sqlguard` user with appropriate permissions
2. **Guardium connects to MySQL** - Uses the `sqlguard` user to securely access your database
3. **Automated security scans** - Guardium performs vulnerability assessments on your schedule
4. **Results and alerts** - Findings are stored in Guardium for review
5. **Review and remediate** - Security teams can review findings and take action

### What Gets Scanned?

Guardium vulnerability assessment checks for:
- ✅ **Security configuration** - Weak passwords, excessive privileges, authentication methods
- ✅ **Database configuration** - MySQL version, deprecated features, insecure parameters
- ✅ **Access control** - Overprivileged users, unused accounts, missing RBAC
- ✅ **Encryption settings** - Unencrypted connections, missing SSL/TLS
- ✅ **Compliance violations** - CIS MySQL Benchmark, PCI-DSS, HIPAA, GDPR, SOC 2
- ✅ **Audit logging** - Missing or inadequate audit configurations

---

## 📦 Modules Used

This example uses two Terraform modules:

### 1. `aws-rds-mysql` Module (Local)
**Location:** `../../modules/aws-rds-mysql`

**What it does:**
- Deploys a Lambda function in your VPC
- Creates the `sqlguard` user in MySQL
- Configures database permissions for VA
- Sets up security groups for Lambda access
- Stores credentials in AWS Secrets Manager
- Creates VPC endpoint for Secrets Manager

**Resources created:**
- `aws_lambda_function` - Lambda for database configuration
- `aws_iam_role` - IAM role for Lambda execution
- `aws_iam_policy` - Policies for Lambda permissions
- `aws_security_group` - Security group for Lambda
- `aws_secretsmanager_secret` - Stores sqlguard credentials
- `aws_vpc_endpoint` - VPC endpoint for Secrets Manager

### 2. `connect-datasource-to-va` Module (Remote)
**Location:** `IBM/gdp/guardium//modules/connect-datasource-to-va`

**What it does:**
- Registers MySQL as a datasource in Guardium
- Configures vulnerability assessment schedule
- Manages SSL certificate import
- Handles OAuth authentication

**Resources created:**
- Guardium datasource registration
- Vulnerability assessment configuration
- SSL certificate import

---


## 📋 What You'll Need (Prerequisites)

Before starting, make sure you have:

- ✅ An existing AWS RDS MySQL database (version 5.7 or above)
- ✅ VPC with private subnets
- ✅ Subnets with connectivity to the RDS instance
- ✅ Security groups allowing Lambda to connect to MySQL (port 3306)
- ✅ Master user credentials with superuser privileges
- ✅ A running Guardium Data Protection instance
- ✅ Admin credentials for Guardium
- ✅ OAuth client credentials (generated using `grdapi register_oauth_client`)
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

#### 2.1 Get Your RDS Endpoint and Master Username

```bash
# Set your RDS instance identifier and region
INSTANCE_ID="your-mysql-instance-name"
REGION="us-east-1"

# Get the RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text

# Get the master username
aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].MasterUsername' \
  --output text
```

#### 2.2 Get Your VPC and Subnet Information

```bash
# Get the DB subnet group name
SUBNET_GROUP=$(aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].DBSubnetGroup.DBSubnetGroupName' \
  --output text)

# Get VPC ID and Subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name $SUBNET_GROUP \
  --region $REGION \
  --query 'DBSubnetGroups[0].{VpcId:VpcId,Subnets:Subnets[*].SubnetIdentifier}' \
  --output json
```

#### 2.3 Get Your Database Security Group

```bash
aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId' \
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
cd examples/aws-rds-mysql
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

Now fill in these values:

#### 🔧 Required Settings (You MUST change these)

```hcl
# AWS Configuration
aws_region = "us-west-2"  # Your AWS region

# Database Connection
db_host     = "your-mysql-instance.region.rds.amazonaws.com"  # ← From Step 2.1
db_username = "admin"                                          # ← From Step 2.1
db_password = "YourStrongPasswordHere"                         # ← Master password

# VA User Credentials
sqlguard_username = "sqlguard"                                 # ← VA user to create
sqlguard_password = "StrongPasswordForVAUser"                  # ← Create a strong password

# Network Configuration
vpc_id               = "vpc-xxxxxxxxxxxxxxxxx"                 # ← From Step 2.2
subnet_ids           = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxxxxx"]  # ← From Step 2.2
db_security_group_id = "sg-xxxxxxxxxxxxxxxxx"                  # ← From Step 2.3

# Guardium Server Details
gdp_server   = "your-guardium-server.example.com"  # ← Your Guardium hostname
gdp_port     = "8443"                               # ← Guardium API port
gdp_username = "admin"                              # ← Your Guardium username
gdp_password = "YourGuardiumPassword"               # ← Your Guardium password
client_id    = "client1"                            # ← From Step 3
client_secret = "YourClientSecret"                  # ← From Step 3 output
```

#### ⚙️ Optional Settings (You can customize these)

```hcl
# Resource Naming
name_prefix = "mysql-va"  # Prefix for AWS resource names

# Database Port (only change if you modified the default)
db_port = 3306

# MySQL Datasource Details
datasource_name        = "rds-mysql-va"  # Name shown in Guardium
datasource_description = "MySQL data source onboarded via Terraform"

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
  Owner       = "your-email@example.com"
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

1. **Create Lambda Function** - Deploys a Lambda in your VPC to configure MySQL
2. **Create IAM Role & Policies** - Allows Lambda to access MySQL and Secrets Manager
3. **Create Security Group Rules** - Allows Lambda to connect to MySQL on port 3306
4. **Create `sqlguard` User** - Lambda creates this user in MySQL with read-only permissions
5. **Store Credentials** - Saves sqlguard credentials in AWS Secrets Manager
6. **Create VPC Endpoint** - Allows Lambda to access Secrets Manager from private subnets
7. **Register Datasource in Guardium** - Adds MySQL as a monitored datasource
8. **Configure Vulnerability Assessment** - Sets up automated security scans

---

## 🔐 Configuring Network Access for Guardium

**IMPORTANT:** After deploying this module, you must configure your RDS MySQL security group to allow connections from the Guardium server.

### Why This Is Required

Guardium Data Protection needs direct network access to your MySQL database to perform vulnerability assessments. The Lambda function only sets up the `sqlguard` database user. **Network connectivity must be configured separately.**

### Step 1: Find Guardium's Public IP Address

SSH into your Guardium server and run:

```bash
curl ifconfig.me
```

This will return Guardium's public IP address (e.g., `xxx.xxx.xxx.xxx`).

### Step 2: Add Security Group Rule

Add an ingress rule allowing Guardium's IP to connect on port 3306:

```bash
# Set your variables
SECURITY_GROUP_ID="sg-xxxxxxxxxxxxxxxxx"  # From Step 2.3 above
GUARDIUM_IP="xxx.xxx.xxx.xxx"             # From Step 1
REGION="us-east-1"

# Add the security group rule
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 3306 \
  --cidr ${GUARDIUM_IP}/32 \
  --region $REGION \
  --description "Guardium VA access"
```

### Step 3: Verify the Rule

Confirm the rule was added successfully:

```bash
aws ec2 describe-security-groups \
  --group-ids $SECURITY_GROUP_ID \
  --region $REGION \
  --query 'SecurityGroups[0].IpPermissions[?ToPort==`3306`]' \
  --output table
```

### Step 4: Test Connection from Guardium

From your Guardium server, test the connection:

```bash
# Test basic connectivity
nc -zv your-mysql-instance.rds.amazonaws.com 3306

# Test MySQL connection (if mysql client is installed)
mysql -h your-mysql-instance.rds.amazonaws.com -P 3306 -u sqlguard -p -e "SELECT 1;"
```

---

## 📊 View Your Results

After successful deployment:

1. Log into your Guardium Data Protection console
2. Navigate to **Data Sources** to see your registered MySQL datasource
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
- Ensure inbound rule allows traffic from Lambda security group on port 3306
- Verify Lambda subnets have route to database subnets
- Check that subnets have route to NAT Gateway or VPC endpoints

### Problem: "Authentication failed for user"
**Solution:**
- Verify db_username and db_password in terraform.tfvars
- Check for typos or extra spaces
- Verify RDS master user: `aws rds describe-db-instances --db-instance-identifier your-db-name --query 'DBInstances[0].MasterUsername'`
- Ensure master user has superuser privileges

### Problem: "Guardium connection failed"
**Solution:**
- Test network connectivity: `curl -k https://your-guardium-server:8443`
- Verify OAuth credentials: SSH to Guardium and run `grdapi list_oauth_clients`
- Check gdp_username and gdp_password are correct
- Ensure Guardium user has admin privileges
- Verify you added Guardium IP to MySQL security group (see "Configuring Network Access" section)

### Problem: "VPC Endpoint Already Exists"
**Solution:**
If you see: `VpcEndpointAlreadyExists: VpcEndpoint already exists in this VPC`

1. Find the existing VPC endpoint ID:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters Name=vpc-id,Values=<your-vpc-id> \
              Name=service-name,Values=com.amazonaws.<your-region>.secretsmanager \
     --region <your-region> \
     --query 'VpcEndpoints[].VpcEndpointId' \
     --output text
   ```

2. Import the existing endpoint into Terraform state:
   ```bash
   terraform import \
     'module.mysql_va_config.aws_vpc_endpoint.secretsmanager' \
     <vpc-endpoint-id>
   ```

3. Re-run terraform apply:
   ```bash
   terraform apply
   ```

### Problem: "Secrets Manager Secret Already Scheduled for Deletion"
**Solution:**
If you see: `You can't create this secret because a secret with this name is already scheduled for deletion`

**Option A: Force delete and create new** (recommended):
```bash
# Find the secret ARN
SECRET_NAME="guardium-mysql-va-xxx-xxxx-xxx-xx-password"  # From error message
REGION="us-east-1"

aws secretsmanager list-secrets \
  --include-planned-deletion \
  --filters Key=name,Values=$SECRET_NAME \
  --region $REGION \
  --query 'SecretList[0].ARN' \
  --output text

# Force delete immediately
SECRET_ARN="<arn-from-above>"
aws secretsmanager delete-secret \
  --secret-id $SECRET_ARN \
  --force-delete-without-recovery \
  --region $REGION

# Re-run terraform apply
terraform apply
```

**Option B: Use a different secret name**:
- Update the `name_prefix` variable in your `terraform.tfvars` to use a different value

### Problem: "Assessment not running"
**Solution:**
- Check data source status in Guardium console (should show "Connected")
- Run manual assessment: Guardium → Vulnerability Assessment → Run Assessment Now
- Check Lambda CloudWatch logs: `aws logs tail /aws/lambda/your-function-name --follow`

---

## 🔐 Security Best Practices

1. **Never commit `terraform.tfvars` to version control** - It contains sensitive passwords
2. **Use strong passwords** - Minimum 12 characters with mixed case, numbers, and symbols
3. **Rotate credentials regularly** - Change passwords every 90 days
4. **Use least privilege** - Only grant necessary IAM permissions
5. **Enable SSL/TLS** - Keep `use_ssl = true` (default)
6. **Deploy Lambda in private subnets** - Never use public subnets
7. **Use /32 CIDR for Guardium** - Only allow the specific Guardium IP address
8. **Review findings regularly** - Check vulnerability assessment reports weekly
9. **Enable CloudWatch alarms** - Monitor Lambda errors and failures
10. **Use separate passwords** - Never reuse passwords across environments

---

## 📚 Additional Resources

- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [AWS RDS MySQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)
- [MySQL Security Best Practices](https://dev.mysql.com/doc/refman/8.0/en/security.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🆘 Need Help?

- Check the [Troubleshooting](#-troubleshooting) section above
- Review Terraform logs: `terraform apply` output
- Check Lambda CloudWatch logs for detailed error messages
- Review module documentation: `../../modules/aws-rds-mysql/README.md`
- Contact your Guardium administrator
- Open an issue in the GitHub repository

---

## 📝 Quick Reference: All Variables

| Variable | Required? | Default | Description |
|----------|-----------|---------|-------------|
| `aws_region` | No | `us-east-1` | AWS region where resources will be created |
| `name_prefix` | No | `rds-mysql-sql` | Prefix for AWS resource names |
| `db_host` | **Yes** | - | RDS MySQL endpoint |
| `db_port` | No | `3306` | MySQL port |
| `db_username` | No | `guardium_admin` | Master username for database |
| `db_password` | **Yes** | - | Master password for database |
| `sqlguard_username` | No | `sqlguard` | Username for VA user |
| `sqlguard_password` | **Yes** | - | Password for VA user |
| `vpc_id` | **Yes** | - | VPC ID where database is deployed |
| `subnet_ids` | **Yes** | - | List of subnet IDs for Lambda |
| `db_security_group_id` | **Yes** | - | Security group ID of MySQL database |
| `gdp_server` | **Yes** | - | Guardium server hostname or IP |
| `gdp_port` | No | `8443` | Guardium API port |
| `gdp_username` | **Yes** | - | Guardium admin username |
| `gdp_password` | **Yes** | - | Guardium admin password |
| `client_id` | No | `client1` | OAuth client ID |
| `client_secret` | **Yes** | - | OAuth client secret from grdapi command |
| `datasource_name` | No | `rds-mysql-va` | Display name in Guardium |
| `datasource_description` | No | `MySQL data source...` | Description in Guardium |
| `application` | No | `Security Assessment` | Datasource category |
| `severity_level` | No | `MED` | Criticality level (LOW/NONE/MED/HIGH) |
| `enable_vulnerability_assessment` | No | `true` | Enable VA scans |
| `use_ssl` | No | `true` | Enable SSL/TLS encryption |
| `import_server_ssl_cert` | No | `true` | Auto-import AWS RDS CA certificate |
| `tags` | No | `{}` | AWS resource tags |
