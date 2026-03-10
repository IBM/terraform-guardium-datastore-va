# AWS DynamoDB with Vulnerability Assessment - Quick Start Guide

This guide helps you set up vulnerability assessment for AWS DynamoDB using IBM Guardium Data Protection. Follow the steps in order for a smooth setup.

> **🔒 Security Note:** SSL/TLS encryption is enabled by default for all Guardium connections to AWS services.

---

## 🏗️ What This Example Does

This Terraform configuration:
- **Creates IAM roles and policies** that allow Guardium to securely access your DynamoDB tables
- **Registers DynamoDB as a datasource** in Guardium Data Protection
- **Configures vulnerability assessment** to automatically scan for security issues

### Architecture Overview

```
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│                   │     │                   │     │                   │
│  AWS DynamoDB     │     │  IAM Role/Policy  │     │  Guardium Data    │
│  Service          │◄────┤  for VA           │◄────┤  Protection       │
│                   │     │                   │     │                   │
└───────────────────┘     └───────────────────┘     └───────────────────┘
                                                           │
                                                           │ Performs
                                                           ▼
                                                    ┌───────────────────┐
                                                    │                   │
                                                    │  Vulnerability    │
                                                    │  Assessment       │
                                                    │                   │
                                                    └───────────────────┘
                                                           │
                                                           │ Generates
                                                           ▼
                                                    ┌───────────────────┐
                                                    │                   │
                                                    │  Assessment       │
                                                    │  Reports          │
                                                    │                   │
                                                    └───────────────────┘
```

### How It Works (Data Flow)

1. **Terraform creates IAM resources** - Sets up the necessary permissions for Guardium
2. **Guardium connects to DynamoDB** - Uses the IAM role to securely access your tables
3. **Automated security scans** - Guardium performs vulnerability assessments on your schedule
4. **Results and alerts** - Findings are stored in Guardium for review
5. **Review and remediate** - Security teams can review findings and take action

### What Gets Scanned?

Guardium vulnerability assessment checks for:
- ✅ **Access control issues** - Overly permissive IAM policies
- ✅ **Encryption settings** - Tables without encryption at rest
- ✅ **Backup configurations** - Missing or inadequate backup policies
- ✅ **Network security** - VPC endpoint configurations
- ✅ **Compliance violations** - Deviations from security best practices
- ✅ **Configuration weaknesses** - Insecure DynamoDB settings

---

## 📦 Modules Used

This example uses two Terraform modules:

### 1. `aws-dynamodb` Module (Local)
**Location:** `../../modules/aws-dynamodb`

**What it does:**
- Creates IAM role for Guardium to assume
- Creates IAM policy with DynamoDB read permissions
- Attaches policy to role
- Outputs role ARN for Guardium configuration

**Resources created:**
- `aws_iam_role` - Role for Guardium
- `aws_iam_policy` - Policy with DynamoDB permissions
- `aws_iam_role_policy_attachment` - Links policy to role

### 2. `connect-datasource-to-va` Module (Remote)
**Location:** `IBM/gdp/guardium//modules/connect-datasource-to-va`

**What it does:**
- Registers DynamoDB as a datasource in Guardium
- Configures vulnerability assessment schedule
- Manages Guardium API authentication

**Resources created:**
- Guardium datasource registration
- Vulnerability assessment configuration

---


## 📋 What You'll Need (Prerequisites)

Before starting, make sure you have:

- ✅ An AWS account with DynamoDB tables
- ✅ A running Guardium Data Protection instance
- ✅ AWS credentials with permissions to create IAM roles
- ✅ Terraform installed (version 1.0.0 or higher)
- ✅ AWS CLI installed and configured

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

### Step 2: Set Up AWS Secrets Manager (REQUIRED)

DynamoDB requires AWS Secrets Manager for authentication.

#### Find AWS Secrets Manager Configuration in Guardium UI

1. Log into your Guardium Data Protection web interface
2. Navigate to: **Setup → Tools and Views → Secrets Management**
3. Look for an existing **AWS Secrets Manager** configuration
4. Note the **Configuration Name** (e.g., `guardium-aws`) - you'll need this in Step 3

> 💡 **If you don't see an AWS Secrets Manager configuration:** Contact your Guardium administrator to set one up. The configuration should include your AWS credentials and the region where your DynamoDB tables are located.

> 💡 **Remember:** The configuration name you find here will be used in Step 3 as `aws_secrets_manager_name`.

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
cd examples/aws-dynamodb
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

Now fill in these values:

#### 🔧 Required Settings (You MUST change these)

```hcl
# Your Guardium server details
gdp_server        = "guardium.example.com"      # ← Your Guardium hostname
guardium_username = "admin"                      # ← Your Guardium username
guardium_password = "your-password"              # ← Your Guardium password
client_id         = "client1"                    # ← From Step 3
client_secret     = "your-client-secret"         # ← From Step 3 output

# AWS Secrets Manager (from Step 2)
aws_secrets_manager_name   = "guardium-aws"              # ← Name from Step 2
aws_secrets_manager_region = "us-east-1"                 # ← Your AWS region
aws_secrets_manager_secret = "dynamodb-credentials"      # ← Secret name in AWS
```

#### ⚙️ Optional Settings (You can customize these)

```hcl
# AWS Configuration
aws_region = "us-east-1"  # Change if your DynamoDB is in a different region

# DynamoDB Datasource Details
dynamodb_datasource_name = "aws-dynamodb-va-example"  # Name shown in Guardium
dynamodb_description     = "AWS DynamoDB with Vulnerability Assessment"

# Application Type (what this datasource is used for)
# Options: "Security Assessment", "Audit Task", "Compliance"
application = "Security Assessment"

# Severity Level (how critical is this datasource)
# Options: "LOW", "MED", "HIGH"
severity_level = "MED"

# Vulnerability Assessment Schedule
enable_vulnerability_assessment = true

# SSL/TLS (Recommended: keep these as true)
use_ssl                = true
import_server_ssl_cert = true

# Debug Mode (set to true if you need to troubleshoot)
debug_mode = false
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

1. **Create IAM Role & Policy** - Allows Guardium to access your DynamoDB tables
2. **Register Datasource in Guardium** - Adds DynamoDB as a monitored datasource
3. **Configure Vulnerability Assessment** - Sets up automated security scans

---

## 📊 View Your Results

After successful deployment:

1. Log into your Guardium Data Protection console
2. Navigate to **Data Sources** to see your registered DynamoDB datasource
3. Go to **Vulnerability Assessment** to view scan results

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
- **"MED"** - Staging or non-critical production
- **"HIGH"** - Critical production systems

---

## 🛠️ Troubleshooting

### Problem: "Authentication failed"
**Solution:** 
- Verify your Guardium username and password
- Check that your OAuth client_secret is correct
- Ensure your Guardium server is accessible

### Problem: "AWS Secrets Manager configuration not found"
**Solution:**
- Make sure you completed Step 2.2 (Register in Guardium UI)
- Verify the `aws_secrets_manager_name` matches exactly what you entered in Guardium UI
- Configuration names are case-sensitive!

### Problem: "Permission denied" errors
**Solution:**
- Verify your AWS credentials have IAM permissions
- Check that the AWS secret exists: `aws secretsmanager describe-secret --secret-id dynamodb-credentials`

### Enable Debug Mode
If you're still having issues, enable debug mode in your `terraform.tfvars`:
```hcl
debug_mode = true
```

Then run `terraform apply` again to see detailed API responses.

---

## 🔐 Security Best Practices

1. **Never commit `terraform.tfvars` to version control** - It contains sensitive passwords
2. **Use strong passwords** for Guardium and AWS credentials
3. **Rotate credentials regularly** - Change passwords every 90 days
4. **Use least privilege** - Only grant necessary IAM permissions
5. **Enable SSL/TLS** - Keep `use_ssl = true` (default)
6. **Review findings regularly** - Check vulnerability assessment reports weekly

---

## 📚 Additional Resources

- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [AWS DynamoDB Security Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices-security.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 🆘 Need Help?

- Check the [Troubleshooting](#-troubleshooting) section above
- Review Terraform logs: `terraform apply` output
- Contact your Guardium administrator
- Open an issue in the GitHub repository

---

## 📝 Quick Reference: All Variables

| Variable | Required? | Default | Description |
|----------|-----------|---------|-------------|
| `aws_region` | No | `us-east-1` | AWS region where DynamoDB is deployed |
| `gdp_server` | **Yes** | - | Your Guardium server hostname |
| `gdp_port` | No | `8443` | Guardium API port |
| `guardium_username` | **Yes** | - | Guardium admin username |
| `guardium_password` | **Yes** | - | Guardium admin password |
| `client_id` | No | `client1` | OAuth client ID |
| `client_secret` | **Yes** | - | OAuth client secret from grdapi command |
| `aws_secrets_manager_name` | **Yes** | - | Name of AWS config in Guardium UI |
| `aws_secrets_manager_region` | **Yes** | - | AWS region for Secrets Manager |
| `aws_secrets_manager_secret` | **Yes** | - | Name of secret in AWS Secrets Manager |
| `dynamodb_datasource_name` | No | `aws-dynamodb-va-example` | Display name in Guardium |
| `dynamodb_description` | No | `AWS DynamoDB with VA` | Description in Guardium |
| `application` | No | `Security Assessment` | Datasource category |
| `severity_level` | No | `MED` | Criticality level (LOW/MED/HIGH) |
| `enable_vulnerability_assessment` | No | `true` | Enable VA scans |
| `use_ssl` | No | `true` | Enable SSL/TLS encryption |
| `import_server_ssl_cert` | No | `true` | Auto-import AWS SSL certificate |
| `debug_mode` | No | `false` | Enable detailed logging |
| `tags` | No | `{}` | AWS resource tags |