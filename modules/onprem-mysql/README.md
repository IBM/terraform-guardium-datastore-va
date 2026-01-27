# On-Premise MySQL Vulnerability Assessment Module

This Terraform module configures Vulnerability Assessment (VA) for on-premise MySQL databases with IBM Guardium Data Protection. Unlike the AWS RDS MySQL module, this module does not require AWS Lambda, VPC, or other AWS services, making it suitable for MySQL databases hosted on-premise or in non-AWS environments.

## Features

- ✅ **No AWS Dependencies**: Works with any MySQL database accessible over the network
- ✅ **SSL Support**: Supports SSL/TLS connections (--ssl-mode=REQUIRED)
- ✅ **Direct Connection**: Connects directly to your on-premise MySQL database
- ✅ **Automated VA Setup**: Registers the database with Guardium for vulnerability assessments
- ✅ **Flexible Scheduling**: Configure assessment schedules (daily, weekly, monthly)
- ✅ **Email Notifications**: Get notified about security findings

## Prerequisites

1. **MySQL Database**: An accessible on-premise MySQL database (version 5.7 or higher recommended)
   - **MySQL 9.6 Users**: See [MySQL 9.6 Troubleshooting Guide](./MYSQL_9.6_TROUBLESHOOTING.md) for version-specific considerations
2. **Network Connectivity**: Guardium must be able to reach your MySQL database
3. **MySQL Admin Access**: Database credentials with privileges to create users and grant permissions
   - For MySQL 9.6+, root user may need remote access configured (see troubleshooting guide)
4. **Guardium Data Protection**: A configured Guardium instance with API access
5. **Terraform**: Version 1.3 or higher
6. **MySQL Client**: MySQL command-line client installed on the machine running Terraform

## MySQL Connection Example

This module supports MySQL databases that you connect to like this:

```bash
mysql -h api.rr1.cp.fyre.ibm.com -u root -p -P 3306 --ssl-mode=REQUIRED
```

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

1. **Credentials**: Store sensitive credentials in Terraform variables or a secrets manager
2. **SSL/TLS**: Enable SSL for production databases (`use_ssl = true`)
3. **Network Security**: Use firewalls to restrict access to MySQL
4. **Least Privilege**: The `sqlguard` user is created with minimal required permissions

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