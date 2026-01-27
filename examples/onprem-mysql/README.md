# On-Premise MySQL Vulnerability Assessment Example

This example demonstrates how to configure Vulnerability Assessment (VA) for an on-premise MySQL database using IBM Guardium Data Protection.

## ⚠️ IMPORTANT SECURITY NOTICE

**SSL Certificate Verification**: This example now uses **secure defaults** with SSL certificate verification enabled (`import_server_ssl_cert = true`). This is critical for production security to prevent man-in-the-middle attacks.

**If you're upgrading from an older version**, please review your SSL configuration. Previous versions had insecure defaults that were NOT production-ready.

## Overview

This example shows how to:
- Connect to an on-premise MySQL database (e.g., `mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED`)
- Register the database with Guardium for vulnerability assessments
- Configure **secure** SSL/TLS connections with certificate verification
- Set up automated assessment schedules
- Configure email notifications for security findings

## Prerequisites

1. **On-Premise MySQL Database**
   - **Supported Versions**: MySQL 5.7, 8.0, 8.4, 9.0, 9.1
   - Network accessible from Guardium
   - Admin credentials with privileges to create users
   - **⚠️ SECURITY**: Use a dedicated admin user, NOT root (see setup below)

2. **Guardium Data Protection**
   - Guardium instance with API access
   - OAuth credentials (client_id and client_secret)
   - Network connectivity to your MySQL database

3. **Terraform**
   - Version 1.3 or higher
   - IBM Guardium provider configured

4. **MySQL Client**
   - MySQL command-line client installed on your machine
   ```bash
   # Check if installed
   mysql --version
   ```

## Initial Setup

### Step 1: Check Your MySQL Version

```bash
# Connect and check version
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 -e "SELECT VERSION();"

# Example output:
# +-----------+
# | VERSION() |
# +-----------+
# | 8.0.44    |
# +-----------+
```

### Step 2: Create Dedicated Admin User (Recommended)

**⚠️ Do NOT use root for Terraform!** Create a dedicated admin user:

```sql
-- Connect as root (one-time setup)
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

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

### Step 3: Test the Admin User

```bash
# Test connection with the new admin user
mysql -h api.rr1.cp.fyre.ibm.com -u terraform_admin -p -P 3306 --ssl-mode=REQUIRED

# Verify it can create users (test command)
mysql -h api.rr1.cp.fyre.ibm.com -u terraform_admin -p -P 3306 --ssl-mode=REQUIRED \
  -e "SELECT USER(), CURRENT_USER(); SHOW GRANTS;"
```

## Quick Start

### 1. Clone and Navigate

```bash
cd terraform-guardium-datastore-va/examples/onprem-mysql
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Database Connection (example: api.rr1.cp.fyre.ibm.com)
db_host     = "api.rr1.cp.fyre.ibm.com"
db_port     = 3306
db_username = "terraform_admin"  # Use dedicated admin user, NOT root!
db_password = "your-admin-password"

# VA User Credentials (will be created by Terraform)
sqlguard_username = "sqlguard"
sqlguard_password = "your-secure-sqlguard-password"

# Guardium Connection
gdp_server    = "your-guardium-server.example.com"
gdp_username  = "your-guardium-username"
gdp_password  = "your-guardium-password"
client_id     = "your-oauth-client-id"
client_secret = "your-oauth-client-secret"

# Datasource Configuration
datasource_name        = "onprem-mysql-fyre"
datasource_description = "On-premise MySQL at api.rr1.cp.fyre.ibm.com"

# SSL Configuration (for --ssl-mode=REQUIRED)
use_ssl = true

# Notifications
notification_emails = ["security-team@example.com"]
```

### 3. Test MySQL Connection and Verify SSL Certificate

Before running Terraform, verify you can connect to MySQL and check the SSL certificate:

```bash
# Test basic connection
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306

# Test SSL connection (if using SSL)
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

# Verify SSL is enabled and check cipher
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED -e "SHOW STATUS LIKE 'Ssl_cipher';"

# View the server's SSL certificate (one-liner - no file saved)
openssl s_client -connect api.rr1.cp.fyre.ibm.com:3306 -starttls mysql -showcerts 2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject:"
```

**Important**: When `import_server_ssl_cert = true` (the default), Guardium automatically retrieves and verifies the server's SSL certificate. You don't need to manually extract or save certificate files.

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

### 6. Apply Configuration

```bash
terraform apply
```

Review the changes and type `yes` to proceed.

## What Gets Created

1. **Guardium Datasource**: Your MySQL database is registered in Guardium
2. **VA Schedule**: Automated vulnerability assessments are configured
3. **Notifications**: Email alerts for security findings are set up

## Configuration Options

### SSL/TLS Configuration

**For Production Databases (RECOMMENDED):**

```hcl
use_ssl                = true   # Enable SSL/TLS encryption
import_server_ssl_cert = true   # Verify server certificate (DEFAULT - secure)
```

**⚠️ For Development/Testing Only (NOT RECOMMENDED FOR PRODUCTION):**

```hcl
use_ssl                = true
import_server_ssl_cert = false  # Disables certificate verification - INSECURE!
```

**Why Certificate Verification Matters:**
- **With verification** (`import_server_ssl_cert = true`): Guardium validates the MySQL server's identity, preventing man-in-the-middle attacks
- **Without verification** (`import_server_ssl_cert = false`): Connection is encrypted but vulnerable to MITM attacks - an attacker can impersonate your MySQL server

**Always use certificate verification in production environments!**

### Assessment Schedule

Configure when vulnerability assessments run:

```hcl
assessment_schedule = "weekly"   # Options: daily, weekly, monthly
assessment_day      = "Monday"   # Day of week or day of month
assessment_time     = "02:00"    # 24-hour format
```

### Notification Settings

Control who gets notified and when:

```hcl
enable_notifications  = true
notification_emails   = ["security@example.com", "dba@example.com"]
notification_severity = "HIGH"  # Options: HIGH, MED, LOW, NONE
```

## Outputs

After successful deployment, you'll see:

```
datasource_name                  = "onprem-mysql-fyre"
datasource_host                  = "api.rr1.cp.fyre.ibm.com"
datasource_port                  = 3306
vulnerability_assessment_enabled = true
assessment_schedule              = "weekly"
ssl_enabled                      = true
```

## Verification

### 1. Check Guardium Console

Log into your Guardium console and verify:
- The datasource appears in the datasource list
- VA schedule is configured
- Test connection is successful

### 2. Verify MySQL User

Connect to MySQL and check the sqlguard user was created:

```sql
SELECT User, Host FROM mysql.user WHERE User = 'sqlguard';
SHOW GRANTS FOR 'sqlguard'@'%';
```

### 3. Test VA Scan

Trigger a manual vulnerability assessment from Guardium to verify everything works.

## Troubleshooting

### Connection Issues

**Problem**: Guardium cannot connect to MySQL

**Solutions**:
1. Verify network connectivity:
   ```bash
   telnet api.rr1.cp.fyre.ibm.com 3306
   ```
2. Check firewall rules allow traffic from Guardium
3. Verify MySQL is listening on the correct interface:
   ```sql
   SHOW VARIABLES LIKE 'bind_address';
   ```

### SSL Issues

**Problem**: SSL connection fails

**Solutions**:
1. Verify MySQL SSL is enabled:
   ```sql
   SHOW VARIABLES LIKE '%ssl%';
   ```
2. Check certificate validity
3. Try setting `import_server_ssl_cert = true`

### Permission Issues

**Problem**: Cannot create sqlguard user

**Solutions**:
1. Verify admin user has sufficient privileges:
   ```sql
   SHOW GRANTS FOR CURRENT_USER();
   ```
2. Check MySQL error logs
3. Ensure user has CREATE USER and GRANT privileges

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Note**: This will:
- Remove the datasource from Guardium
- Delete VA schedules and notifications
- The `sqlguard` user in MySQL will remain (manual cleanup required if needed)

To manually remove the sqlguard user from MySQL:

```sql
DROP USER IF EXISTS 'sqlguard'@'%';
```

## Network Requirements

Ensure the following network connectivity:

```
Guardium Server → MySQL Database (port 3306)
```

If using SSL, ensure certificates are properly configured on both sides.

## Security Best Practices

1. **🔒 SSL/TLS with Certificate Verification**:
   - **Always enable SSL** for production databases (`use_ssl = true`)
   - **Always verify certificates** in production (`import_server_ssl_cert = true` - this is now the default)
   - Without certificate verification, you're vulnerable to man-in-the-middle attacks

2. **Strong Passwords**: Use strong, unique passwords for sqlguard user

3. **Least Privilege**: The sqlguard user is created with minimal required permissions

4. **Secrets Management**: Store credentials in Terraform variables or a secrets manager

5. **Network Security**: Use firewalls to restrict MySQL access to only Guardium servers

6. **Regular Assessments**: Schedule regular VA scans (at least weekly)

7. **Certificate Management**: Ensure MySQL server certificates are valid and not expired

## Example: Complete terraform.tfvars

```hcl
# Database Connection
db_host     = "api.rr1.cp.fyre.ibm.com"
db_port     = 3306
db_username = "root"
db_password = "SecurePassword123!"

# VA User
sqlguard_username = "sqlguard"
sqlguard_password = "AnotherSecurePassword456!"

# Guardium
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "GuardiumPassword789!"
client_id     = "oauth-client-id-here"
client_secret = "oauth-client-secret-here"

# Datasource
datasource_name        = "onprem-mysql-fyre"
datasource_description = "Production MySQL at IBM Fyre"
severity_level         = "HIGH"

# SSL - SECURE CONFIGURATION FOR PRODUCTION
use_ssl                = true
import_server_ssl_cert = true  # IMPORTANT: Verifies server certificate (default)
                               # Set to false ONLY for dev/test (NOT RECOMMENDED)

# VA Schedule
enable_vulnerability_assessment = true
assessment_schedule             = "weekly"
assessment_day                  = "Sunday"
assessment_time                 = "03:00"

# Notifications
enable_notifications  = true
notification_emails   = ["security@example.com", "dba@example.com"]
notification_severity = "HIGH"

# Tags
tags = {
  Purpose     = "guardium-va-onprem-mysql"
  Owner       = "security-team@example.com"
  Environment = "production"
  Database    = "mysql-fyre"
  Location    = "on-premise"
}
```

## Additional Resources

- [Module Documentation](../../modules/onprem-mysql/README.md)
- [Guardium Documentation](https://www.ibm.com/docs/en/guardium)
- [MySQL Security Best Practices](https://dev.mysql.com/doc/refman/8.0/en/security.html)

## Support

For issues or questions:
1. Check the module README
2. Review Guardium logs
3. Verify MySQL configuration
4. Check network connectivity

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0