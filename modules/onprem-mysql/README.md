# On-Premise MySQL Vulnerability Assessment Module

This Terraform module configures Vulnerability Assessment (VA) for on-premise MySQL databases with IBM Guardium Data Protection. Unlike the AWS RDS MySQL module, this module does not require AWS Lambda, VPC, or other AWS services, making it suitable for MySQL databases hosted on-premise or in non-AWS environments.

## ⚠️ IMPORTANT SECURITY NOTICE

**SSL Certificate Verification**: When using SSL/TLS connections (`use_ssl = true`), this module now **defaults to verifying the server's SSL certificate** (`import_server_ssl_cert = true`). This is critical for production security to prevent man-in-the-middle attacks.

**Previous versions** of this module had `import_server_ssl_cert = false` by default, which was **NOT production-ready**. If you're upgrading from an older version, please review your SSL configuration.

## Features

- ✅ **No AWS Dependencies**: Works with any MySQL database accessible over the network
- ✅ **Secure SSL/TLS**: Supports SSL/TLS connections with certificate verification
- ✅ **Direct Connection**: Connects directly to your on-premise MySQL database
- ✅ **Automated VA Setup**: Registers the database with Guardium for vulnerability assessments
- ✅ **Flexible Scheduling**: Configure assessment schedules (daily, weekly, monthly)
- ✅ **Email Notifications**: Get notified about security findings

## Prerequisites

1. **MySQL Database**: An accessible on-premise MySQL database
   - **Supported Versions**: MySQL 5.7, 8.0, 8.4, 9.0, 9.1 (check your version with `SELECT VERSION();`)
   - **MySQL 9.x Users**: See [MySQL 9.6 Troubleshooting Guide](./MYSQL_9.6_TROUBLESHOOTING.md) for version-specific considerations
   
2. **Network Connectivity**: Guardium must be able to reach your MySQL database

3. **MySQL Admin Access**: Database credentials with privileges to create users and grant permissions
   - **⚠️ SECURITY RECOMMENDATION**: Do NOT use the root user for Terraform operations
   - Instead, create a dedicated admin user with specific privileges (see below)
   - For MySQL 9.x+, root user may need remote access configured (see troubleshooting guide)

4. **Guardium Data Protection**: A configured Guardium instance with API access

5. **Terraform**: Version 1.3 or higher

6. **MySQL Client**: MySQL command-line client installed on the machine running Terraform
   ```bash
   # Check if mysql client is installed
   mysql --version
   
   # Install if needed:
   # macOS: brew install mysql-client
   # Ubuntu: sudo apt-get install mysql-client
   # RHEL/CentOS: sudo yum install mysql
   ```

### Checking Your MySQL Version

Before using this module, verify your MySQL version:

```bash
# Connect to MySQL and check version
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 -e "SELECT VERSION();"

# Example output:
# +-----------+
# | VERSION() |
# +-----------+
# | 8.0.44    |
# +-----------+
```

### Creating a Dedicated Admin User (Recommended)

**Instead of using root**, create a dedicated admin user for Terraform operations:

```sql
-- Connect as root
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

-- Create a dedicated admin user for Terraform
CREATE USER 'terraform_admin'@'%' IDENTIFIED BY 'SecurePassword123!';

-- Grant necessary privileges to create users and manage permissions
GRANT CREATE USER ON *.* TO 'terraform_admin'@'%';
GRANT SELECT, PROCESS, SHOW DATABASES ON *.* TO 'terraform_admin'@'%';
GRANT GRANT OPTION ON *.* TO 'terraform_admin'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify the user was created
SELECT User, Host FROM mysql.user WHERE User = 'terraform_admin';
```

Then use `terraform_admin` instead of `root` in your `terraform.tfvars`:

```hcl
db_username = "terraform_admin"  # NOT root!
db_password = "SecurePassword123!"
```

## MySQL Connection Example

This module supports MySQL databases that you connect to like this:

```bash
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

## Built-in Terraform Validations

This module includes comprehensive Terraform-native validations that run during `terraform plan` to catch configuration issues early:

### 1. **Admin User Security Check**
- **Validates**: Admin user should not be 'root'
- **Why**: Using root violates security best practices
- **Fix**: Create a dedicated admin user (see above)

### 2. **Password Strength Validation**
- **Validates**: sqlguard password meets MySQL 9.x requirements
- **Requirements**:
  - Minimum 8 characters
  - At least one uppercase letter (A-Z)
  - At least one lowercase letter (a-z)
  - At least one number (0-9)
  - At least one special character (!@#$%^&*)
- **Example**: `SqlGuard@2024!Strong`

### 3. **User Separation Check**
- **Validates**: sqlguard_username ≠ db_username
- **Why**: Separation of duties - admin user vs. read-only VA user
- **Fix**: Use different usernames for each role

### 4. **SSL Configuration Validation**
- **Validates**: If SSL is enabled, certificate verification should be enabled
- **Why**: Prevents man-in-the-middle attacks
- **Fix**: Set `import_server_ssl_cert = true`

### 5. **Port Number Validation**
- **Validates**: Port is between 1-65535
- **Standard**: MySQL uses port 3306

### 6. **Hostname Format Validation**
- **Validates**: Hostname or IP address format is valid
- **Examples**: `mysql.example.com`, `192.168.1.100`

## Configuration Best Practices

### ✅ Recommended Configuration

```hcl
# Use dedicated admin user (not root)
db_username = "terraform_admin"
db_password = "StrongAdminPass123!"

# Use strong password for sqlguard user
sqlguard_username = "sqlguard"
sqlguard_password = "SqlGuard@2024!Strong"

# Enable SSL with certificate verification
use_ssl                = true
import_server_ssl_cert = true

# Configure VA schedule
assessment_schedule = "weekly"
assessment_day      = "Monday"
assessment_time     = "02:00"
```

### ❌ Configurations to Avoid

```hcl
# DON'T use root user
db_username = "root"  # ❌ Fails validation, security risk

# DON'T use weak passwords
sqlguard_password = "simple123"  # ❌ Fails validation, won't meet MySQL 9.x requirements

# DON'T use same user for admin and VA
db_username       = "admin"
sqlguard_username = "admin"  # ❌ Fails validation, violates separation of duties

# DON'T disable SSL certificate verification in production
use_ssl                = true
import_server_ssl_cert = false  # ❌ Warning, vulnerable to MITM attacks
```

## MySQL Version Compatibility

This module is designed to work universally across MySQL versions:

| MySQL Version | Authentication Plugin | Status |
|---------------|----------------------|--------|
| MySQL 5.7 | `mysql_native_password` | ✅ Supported |
| MySQL 8.0 | `caching_sha2_password` | ✅ Supported |
| MySQL 8.4 | `caching_sha2_password` | ✅ Supported |
| MySQL 9.0 | `caching_sha2_password` | ✅ Supported |
| MySQL 9.1+ | `caching_sha2_password` | ✅ Supported |

**Note**: The module uses `caching_sha2_password` for user creation, which is compatible with MySQL 8.0+ and is the default in MySQL 9.x.

```

## Verifying SSL Certificate (One-Liner)

Before deploying, you can verify the MySQL server's SSL certificate is valid:

```bash
# View the server's SSL certificate details
openssl s_client -connect api.rr1.cp.fyre.ibm.com:3306 -starttls mysql -showcerts 2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject:"

# Or extract and view the full certificate
openssl s_client -connect api.rr1.cp.fyre.ibm.com:3306 -starttls mysql -showcerts 2>/dev/null | openssl x509 -noout -text
```

**Note**: When `import_server_ssl_cert = true` (the default), Guardium will automatically retrieve and verify this certificate. You don't need to manually save or provide the certificate file.

## Usage

### Basic Example

```hcl
module "onprem_mysql_va" {
  source = "path/to/modules/onprem-mysql"

  # Database Connection
  db_host     = "api.rr1.cp.fyre.ibm.com"
  db_port     = 3306
  db_username = "root"
  db_password = var.db_password

  # VA User Credentials
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # Guardium Connection
  gdp_server    = "guardium.example.com"
  gdp_username  = var.gdp_username
  gdp_password  = var.gdp_password
  client_id     = var.client_id
  client_secret = var.client_secret

  # Datasource Configuration
  datasource_name        = "onprem-mysql-fyre"
  datasource_description = "On-premise MySQL at api.rr1.cp.fyre.ibm.com"

  # SSL Configuration
  use_ssl = true

  # VA Schedule
  enable_vulnerability_assessment = true
  assessment_schedule             = "weekly"
  assessment_day                  = "Monday"
  assessment_time                 = "02:00"

  # Notifications
  enable_notifications  = true
  notification_emails   = ["security@example.com"]
  notification_severity = "HIGH"
}
```

### With SSL Certificate Import

```hcl
module "onprem_mysql_va" {
  source = "path/to/modules/onprem-mysql"

  # ... other configuration ...

  use_ssl                = true
  import_server_ssl_cert = true
}
```

## Required Inputs

| Name | Description | Type |
|------|-------------|------|
| `db_host` | Hostname or IP address of the MySQL database | `string` |
| `db_username` | MySQL admin username (must have superuser privileges) | `string` |
| `db_password` | MySQL admin password | `string` |
| `sqlguard_username` | Username for the Guardium VA user | `string` |
| `sqlguard_password` | Password for the Guardium VA user | `string` |
| `gdp_server` | Guardium Data Protection server hostname | `string` |
| `gdp_username` | Guardium username | `string` |
| `gdp_password` | Guardium password | `string` |
| `client_id` | OAuth client ID for Guardium API | `string` |
| `client_secret` | OAuth client secret for Guardium API | `string` |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `db_port` | MySQL port | `number` | `3306` |
| `datasource_name` | Unique name for the datasource in Guardium | `string` | `"onprem-mysql-va"` |
| `use_ssl` | Enable SSL/TLS connection | `bool` | `true` |
| `assessment_schedule` | Assessment frequency (daily, weekly, monthly) | `string` | `"weekly"` |
| `assessment_day` | Day to run assessment | `string` | `"Monday"` |
| `assessment_time` | Time to run assessment (24-hour format) | `string` | `"02:00"` |
| `notification_emails` | List of email addresses for notifications | `list(string)` | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `datasource_name` | Name of the datasource registered in Guardium |
| `datasource_host` | Hostname of the MySQL database |
| `datasource_port` | Port of the MySQL database |
| `vulnerability_assessment_enabled` | Whether VA is enabled |
| `ssl_enabled` | Whether SSL is enabled |

## How It Works

1. **Direct Connection**: The module configures Guardium to connect directly to your on-premise MySQL database
2. **User Creation**: A dedicated `sqlguard` user is created in MySQL with necessary permissions for VA
3. **Registration**: The database is registered as a datasource in Guardium
4. **Scheduling**: Vulnerability assessments are scheduled according to your configuration
5. **Notifications**: Email notifications are configured for security findings

## Network Requirements

- Guardium must be able to reach your MySQL database on the specified port (default: 3306)
- If using SSL, ensure proper certificates are configured
- Firewall rules must allow traffic from Guardium to MySQL

## Security Considerations

### 🔒 SSL/TLS Certificate Verification (CRITICAL)

**For Production Environments:**
```hcl
use_ssl                = true
import_server_ssl_cert = true  # This is now the default
```

**Why This Matters:**
- **Without certificate verification** (`import_server_ssl_cert = false`), your connection is vulnerable to man-in-the-middle (MITM) attacks
- An attacker can intercept the connection even though it's encrypted
- **Always verify certificates in production** to ensure you're connecting to the legitimate MySQL server

**When to Disable Certificate Verification:**
- Only in development/testing environments where security is not critical
- When you explicitly understand and accept the security risks
- Never in production environments

### Other Security Best Practices

1. **Credentials**: Store sensitive credentials in Terraform variables or a secrets manager
2. **SSL/TLS**: Always enable SSL for production databases (`use_ssl = true`)
3. **Certificate Verification**: Keep `import_server_ssl_cert = true` (default) for production
4. **Network Security**: Use firewalls to restrict access to MySQL
5. **Least Privilege**: The `sqlguard` user is created with minimal required permissions
6. **Regular Assessments**: Schedule regular VA scans (at least weekly)

## Troubleshooting

### MySQL 9.6 Specific Issues

**⚠️ If you're using MySQL 9.6, please see the [MySQL 9.6 Troubleshooting Guide](./MYSQL_9.6_TROUBLESHOOTING.md) for detailed solutions.**

Common MySQL 9.6 issues:
- **ERROR 1045 (28000): Access denied** - Root user may not have remote access configured
- **Authentication plugin errors** - MySQL 9.6 uses different default authentication
- **Connection timeouts** - Stricter security settings in MySQL 9.6

### Connection Issues

If Guardium cannot connect to MySQL:

1. Verify network connectivity: `telnet api.rr1.cp.fyre.ibm.com 3306`
2. Check firewall rules
3. Verify MySQL is listening on the correct interface
4. Test SSL connection manually if enabled
5. For MySQL 9.6+, verify remote access is configured (see troubleshooting guide)

### SSL Issues

If SSL connection fails:

1. Verify MySQL SSL configuration: `SHOW VARIABLES LIKE '%ssl%';`
2. Check certificate validity
3. Try with `import_server_ssl_cert = true`

### Permission Issues

If VA fails due to permissions:

1. Verify admin user has sufficient privileges
2. Check MySQL error logs
3. Ensure `sqlguard` user was created successfully
4. For MySQL 9.6+, verify authentication plugin compatibility

## Example: Testing Connection

Before running Terraform, test your MySQL connection:

```bash
# Test basic connection
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306

# Test SSL connection
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

# Verify SSL is enabled
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 -e "SHOW VARIABLES LIKE '%ssl%';"
```

## Complete Example

See the [examples/onprem-mysql](../../examples/onprem-mysql) directory for a complete working example.

## Support

For issues or questions:
- Check the [main README](../../README.md)
- Review Guardium documentation
- Verify MySQL configuration

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0