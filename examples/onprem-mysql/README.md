# On-Premise MySQL Vulnerability Assessment Example

This example demonstrates how to configure Vulnerability Assessment (VA) for an on-premise MySQL database using IBM Guardium Data Protection.

## Overview

This example shows how to:
- Connect to an on-premise MySQL database (e.g., `mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED`)
- Register the database with Guardium for vulnerability assessments
- Configure SSL/TLS connections
- Set up automated assessment schedules
- Configure email notifications for security findings

## Prerequisites

1. **On-Premise MySQL Database**
   - MySQL 5.7 or higher
   - Network accessible from Guardium
   - Admin credentials with privileges to create users

2. **Guardium Data Protection**
   - Guardium instance with API access
   - OAuth credentials (client_id and client_secret)
   - Network connectivity to your MySQL database

3. **Terraform**
   - Version 1.3 or higher
   - IBM Guardium provider configured

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
db_username = "root"
db_password = "your-mysql-root-password"

# VA User Credentials
sqlguard_username = "sqlguard"
sqlguard_password = "your-secure-password"

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

### 3. Test MySQL Connection

Before running Terraform, verify you can connect to MySQL:

```bash
# Test basic connection
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306

# Test SSL connection (if using SSL)
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED

# Verify SSL status
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 -e "SHOW VARIABLES LIKE '%ssl%';"
```

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

For databases requiring SSL (like `--ssl-mode=REQUIRED`):

```hcl
use_ssl                = true
import_server_ssl_cert = false  # Set to true if you need to import the server certificate
```

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

1. **Use SSL/TLS**: Always enable SSL for production databases
2. **Strong Passwords**: Use strong, unique passwords for sqlguard user
3. **Least Privilege**: The sqlguard user is created with minimal required permissions
4. **Secrets Management**: Store credentials in Terraform variables or a secrets manager
5. **Network Security**: Use firewalls to restrict MySQL access
6. **Regular Assessments**: Schedule regular VA scans (at least weekly)

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

# SSL
use_ssl                = true
import_server_ssl_cert = false

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