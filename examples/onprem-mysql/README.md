# On-Premise MySQL with Vulnerability Assessment - Quick Start Guide

This guide helps you set up vulnerability assessment for on-premise MySQL using IBM Guardium Data Protection. Follow the steps in order for a smooth setup.

> **🔒 Security Note:** SSL/TLS encryption with certificate verification is enabled by default (`import_server_ssl_cert = true`) to prevent man-in-the-middle attacks.

---

## 🏗️ What This Example Does

This Terraform configuration:
- **Connects to your on-premise MySQL database** directly from Guardium
- **Creates a dedicated `sqlguard` user** with read-only permissions for security assessments
- **Registers MySQL as a datasource** in Guardium Data Protection
- **Configures vulnerability assessment** to automatically scan for security issues
- **Enables SSL/TLS with certificate verification** by default for secure connections

### Architecture Overview

```
Guardium Server → MySQL Database (port 3306)
```

If using SSL, ensure certificates are properly configured on both sides.

### How It Works (Data Flow)

1. **Terraform configures Guardium** - Registers your on-premise MySQL database as a datasource
2. **Guardium connects to MySQL** - Uses the `sqlguard` user credentials to access your database
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

This example uses one Terraform module:

### `onprem-mysql` Module (Local)
**Location:** `../../modules/onprem-mysql`

**What it does:**
- Registers on-premise MySQL as a datasource in Guardium
- Configures vulnerability assessment schedule
- Manages SSL certificate import
- Handles OAuth authentication

**Resources created:**
- Guardium datasource registration
- Vulnerability assessment configuration
- SSL certificate import (if enabled)

**Note:** Unlike AWS RDS examples, this module does NOT create a Lambda function. Guardium connects directly to your on-premise MySQL database.

---


## 📋 What You'll Need (Prerequisites)

Before starting, make sure you have:

- ✅ An on-premise MySQL database (versions 5.7, 8.0, 8.4, 9.0, 9.1 supported)
- ✅ Network accessibility from Guardium to MySQL (port 3306)
- ✅ Admin credentials with privileges to create users
- ✅ A running Guardium Data Protection instance
- ✅ Admin credentials for Guardium
- ✅ OAuth client credentials (generated using `grdapi register_oauth_client`)
- ✅ MySQL command-line client installed on your machine
- ✅ Terraform installed (version >= 1.3)

---

## 🚀 Step-by-Step Setup

### Step 1: Verify Your MySQL Version and Connectivity

First, check your MySQL version and test connectivity:

```bash
# Connect and check version
mysql -h your-mysql-host.example.com -u root -p -P 3306 -e "SELECT VERSION();"

# Test SSL connection (if using SSL)
mysql -h your-mysql-host.example.com -u root -p -P 3306 --ssl-mode=REQUIRED

# Verify SSL is enabled and check cipher
mysql -h your-mysql-host.example.com -u root -p -P 3306 --ssl-mode=REQUIRED -e "SHOW STATUS LIKE 'Ssl_cipher';"
```

---

### Step 2: Create Dedicated Admin User (Recommended)

**⚠️ Do NOT use root for Terraform!** Create a dedicated admin user:

```sql
-- Connect as root (one-time setup)
mysql -h your-mysql-host.example.com -u root -p -P 3306 --ssl-mode=REQUIRED

-- Create dedicated admin user for Terraform
CREATE USER 'terraform_admin'@'%' IDENTIFIED BY 'SecurePassword123!';

-- Grant necessary privileges
GRANT CREATE USER ON *.* TO 'terraform_admin'@'%';
GRANT SELECT, PROCESS, SHOW DATABASES ON *.* TO 'terraform_admin'@'%';
GRANT GRANT OPTION ON *.* TO 'terraform_admin'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify
SELECT User, Host FROM mysql.user WHERE User = 'terraform_admin';
SHOW GRANTS FOR 'terraform_admin'@'%';
```

---

### Step 3: Test the Admin User

```bash
# Test connection with the new admin user
mysql -h your-mysql-host.example.com -u terraform_admin -p -P 3306 --ssl-mode=REQUIRED

# Verify it can create users (test command)
mysql -h your-mysql-host.example.com -u terraform_admin -p -P 3306 --ssl-mode=REQUIRED \
  -e "SELECT USER(), CURRENT_USER(); SHOW GRANTS;"
```

---

### Step 4: Get Your Guardium OAuth Credentials

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

### Step 5: Configure Your Variables

Copy the example file and edit it with your values:

```bash
cd examples/onprem-mysql
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

Now fill in these values:

#### 🔧 Required Settings (You MUST change these)

```hcl
# Database Connection
db_host     = "your-mysql-host.example.com"    # ← Your MySQL hostname
db_port     = 3306                             # ← MySQL port
db_username = "root"                           # ← Admin username
db_password = "your-mysql-root-password"       # ← Admin password

# VA User Credentials
sqlguard_username = "sqlguard"                 # ← VA user to create
sqlguard_password = "your-sqlguard-password"   # ← Create a strong password

# Guardium Server Details
gdp_server    = "your-guardium-server.example.com"  # ← Your Guardium hostname
gdp_username  = "your-guardium-username"            # ← Your Guardium username
gdp_password  = "your-guardium-password"            # ← Your Guardium password
client_id     = "your-oauth-client-id"              # ← From Step 4
client_secret = "your-oauth-client-secret"          # ← From Step 4 output
```

#### ⚙️ Optional Settings (You can customize these)

```hcl
# Datasource Details
datasource_name        = "onprem-mysql-fyre"  # Name shown in Guardium
datasource_description = "On-premise MySQL database at your-mysql-host.example.com"

# Application Type (what this datasource is used for)
# Options: "Security Assessment", "Audit Task", "Compliance"
application = "Security Assessment"

# Severity Level (how critical is this datasource)
# Options: "LOW", "NONE", "MED", "HIGH"
severity_level = "MED"

# Vulnerability Assessment
enable_vulnerability_assessment = true

# SSL/TLS Configuration (RECOMMENDED: keep these as true)
# ⚠️ IMPORTANT: Certificate verification prevents man-in-the-middle attacks
use_ssl                = true   # Enable SSL/TLS encryption
import_server_ssl_cert = true   # Verify server certificate (DEFAULT - secure)

# Tags
tags = {
  Purpose     = "guardium-va-onprem-mysql"
  Owner       = "security-team@example.com"
  Environment = "production"
  Database    = "mysql-fyre"
}
```

---

### Step 6: Run Terraform

Now you're ready to deploy!

#### 6.1 Initialize Terraform
```bash
terraform init
```

#### 6.2 Preview What Will Be Created
```bash
terraform plan
```

Review the output to see what resources will be created.

#### 6.3 Apply the Configuration
```bash
terraform apply
```

Type `yes` when prompted to confirm.

---

## ✅ What Gets Created

This Terraform configuration will:

1. **Register Datasource in Guardium** - Adds your on-premise MySQL as a monitored datasource
2. **Configure Vulnerability Assessment** - Sets up automated security scans
3. **Import SSL Certificate** - Automatically retrieves and verifies the server's SSL certificate (if enabled)

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

### Why SSL Certificate Verification?
- **With verification** (`import_server_ssl_cert = true`): Guardium validates the MySQL server's identity, preventing man-in-the-middle attacks
- **Without verification** (`import_server_ssl_cert = false`): Connection is encrypted but vulnerable to MITM attacks - an attacker can impersonate your MySQL server

**Always use certificate verification in production environments!**

---

## 🛠️ Troubleshooting

### Problem: "Guardium cannot connect to MySQL"
**Solution:**
- Verify network connectivity: `telnet your-mysql-host.example.com 3306`
- Check firewall rules allow traffic from Guardium
- Verify MySQL is listening on the correct interface:
  ```sql
  SHOW VARIABLES LIKE 'bind_address';
  ```
- Ensure MySQL is accessible from Guardium's network

### Problem: "SSL connection fails"
**Solution:**
- Verify MySQL SSL is enabled:
  ```sql
  SHOW VARIABLES LIKE '%ssl%';
  ```
- Check certificate validity
- Try setting `import_server_ssl_cert = true` (default)
- View the server's SSL certificate:
  ```bash
  openssl s_client -connect your-mysql-host.example.com:3306 -starttls mysql -showcerts 2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject:"
  ```

### Problem: "Cannot create sqlguard user"
**Solution:**
- Verify admin user has sufficient privileges:
  ```sql
  SHOW GRANTS FOR CURRENT_USER();
  ```
- Check MySQL error logs
- Ensure user has CREATE USER and GRANT privileges

### Problem: "Authentication failed"
**Solution:**
- Verify db_username and db_password in terraform.tfvars
- Check for typos or extra spaces
- Test connection manually:
  ```bash
  mysql -h your-mysql-host.example.com -u root -p -P 3306 --ssl-mode=REQUIRED
  ```

### Problem: "Assessment not running"
**Solution:**
- Check data source status in Guardium console (should show "Connected")
- Run manual assessment: Guardium → Vulnerability Assessment → Run Assessment Now
- Check Guardium logs for error messages

---

## 🔐 Security Best Practices

1. **Never commit `terraform.tfvars` to version control** - It contains sensitive passwords
2. **Use strong passwords** - Minimum 12 characters with mixed case, numbers, and symbols
3. **Rotate credentials regularly** - Change passwords every 90 days
4. **Use dedicated admin user** - Create terraform_admin instead of using root
5. **Enable SSL/TLS with certificate verification** - Keep `use_ssl = true` and `import_server_ssl_cert = true` (defaults)
6. **Use firewalls** - Restrict MySQL access to only Guardium servers
7. **Least privilege** - The sqlguard user is created with minimal required permissions
8. **Regular assessments** - Schedule VA scans at least weekly
9. **Certificate management** - Ensure MySQL server certificates are valid and not expired
10. **Review findings regularly** - Check vulnerability assessment reports weekly

---

## 🧹 Cleanup

To remove all resources created by this example:

```bash
terraform destroy
```

**Note:** This will:
- Remove the datasource from Guardium
- Delete VA schedules
- The `sqlguard` user in MySQL will remain (manual cleanup required if needed)

To manually remove the sqlguard user from MySQL:

```sql
DROP USER IF EXISTS 'sqlguard'@'%';
```

---

## 📚 Additional Resources

- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [MySQL Security Best Practices](https://dev.mysql.com/doc/refman/8.0/en/security.html)
- [MySQL SSL/TLS Configuration](https://dev.mysql.com/doc/refman/8.0/en/using-encrypted-connections.html)
- [Terraform Documentation](https://www.terraform.io/docs)

---

## 🆘 Need Help?

- Check the [Troubleshooting](#-troubleshooting) section above
- Review Terraform logs: `terraform apply` output
- Review module documentation: `../../modules/onprem-mysql/README.md`
- Verify MySQL configuration and logs
- Check network connectivity between Guardium and MySQL
- Contact your Guardium administrator
- Open an issue in the GitHub repository

---

## 📝 Quick Reference: All Variables

| Variable | Required? | Default | Description |
|----------|-----------|---------|-------------|
| `db_host` | **Yes** | - | Hostname or IP of on-premise MySQL |
| `db_port` | No | `3306` | MySQL port |
| `db_username` | **Yes** | - | Admin username for MySQL |
| `db_password` | **Yes** | - | Admin password for MySQL |
| `sqlguard_username` | No | `sqlguard` | Username for VA user |
| `sqlguard_password` | **Yes** | - | Password for VA user |
| `gdp_server` | **Yes** | - | Guardium server hostname or IP |
| `gdp_port` | No | `8443` | Guardium API port |
| `gdp_username` | **Yes** | - | Guardium admin username |
| `gdp_password` | **Yes** | - | Guardium admin password |
| `client_id` | **Yes** | - | OAuth client ID |
| `client_secret` | **Yes** | - | OAuth client secret from grdapi command |
| `datasource_name` | No | `onprem-mysql-va` | Display name in Guardium |
| `datasource_description` | No | `On-premise MySQL...` | Description in Guardium |
| `application` | No | `Security Assessment` | Datasource category |
| `severity_level` | No | `MED` | Criticality level (LOW/NONE/MED/HIGH) |
| `enable_vulnerability_assessment` | No | `true` | Enable VA scans |
| `use_ssl` | No | `true` | Enable SSL/TLS encryption |
| `import_server_ssl_cert` | No | `true` | Verify server certificate (RECOMMENDED) |
| `tags` | No | `{}` | Resource tags |