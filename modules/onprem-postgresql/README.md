# On-Premise PostgreSQL Vulnerability Assessment Configuration Module

This module configures an on-premise PostgreSQL database for Guardium Vulnerability Assessment (VA). It creates the necessary users, groups, and permissions required for Guardium to perform security assessments and entitlement reports.

## Features

- ✅ **Terraform-Native Validations**: 6 built-in validation checks catch configuration errors during `terraform plan`
- ✅ **PostgreSQL 10+ Support**: Works with PostgreSQL 10.x through 16.x
- ✅ **Secure User Creation**: Creates `sqlguard` user with minimal required privileges
- ✅ **Group Management**: Creates `gdmmonitor` group and assigns proper permissions
- ✅ **SSL Support**: Optional SSL/TLS encryption for database connections
- ✅ **Password Policy Enforcement**: Validates password strength before deployment
- ✅ **No AWS Dependencies**: Pure PostgreSQL module without Lambda or cloud services
- ✅ **Idempotent**: Safe to run multiple times without errors

## Built-in Terraform Validations

The module includes 6 validation checks that run during `terraform plan`:

1. **Admin User Security**: Warns against using `postgres` superuser
2. **Password Strength**: Enforces strong password requirements (8+ chars, uppercase, lowercase, numbers, special chars)
3. **User Separation**: Ensures sqlguard user is different from admin user
4. **SSL Configuration**: Validates SSL mode settings
5. **Port Validation**: Checks port number is valid (1-65535)
6. **Hostname Format**: Validates hostname/IP format

These validations catch configuration errors **before** any resources are created!

## Prerequisites

- PostgreSQL version 10.x or above (tested with 16.11)
- Admin user with SUPERUSER privileges (to create users and groups)
- PostgreSQL must be configured to accept remote connections
- `psql` client installed on the machine running Terraform
- Network connectivity from Terraform machine to PostgreSQL server

### PostgreSQL Server Configuration

Your PostgreSQL server must be configured for remote access:

```bash
# 1. Edit postgresql.conf
listen_addresses = '*'
password_encryption = 'scram-sha-256'

# 2. Edit pg_hba.conf - add this line:
host    all             all             0.0.0.0/0               scram-sha-256

# 3. Restart PostgreSQL
sudo systemctl restart postgresql

# 4. Open firewall port
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

## Usage

### Basic Usage (No SSL)

```hcl
module "onprem_postgresql_va" {
  source = "../../modules/onprem-postgresql"

  # Database Connection
  db_host     = "postgres.example.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "terraform_admin"
  db_password = var.db_password

  # Guardium VA User
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # SSL Configuration
  use_ssl  = false
  ssl_mode = "disable"
}
```

### Production Usage (With SSL)

```hcl
module "onprem_postgresql_va" {
  source = "../../modules/onprem-postgresql"

  # Database Connection
  db_host     = "postgres.production.com"
  db_port     = 5432
  db_name     = "postgres"
  db_username = "terraform_admin"
  db_password = var.db_password

  # Guardium VA User
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # SSL Configuration (Recommended for Production)
  use_ssl  = true
  ssl_mode = "require"  # or "verify-ca" or "verify-full"

  tags = {
    Environment = "Production"
    Owner       = "Security Team"
    Purpose     = "Guardium VA"
  }
}
```

## Configuration Best Practices

### ✅ DO:

```hcl
# Create a dedicated admin user (not postgres superuser)
db_username = "terraform_admin"

# Use strong passwords
sqlguard_password = "SqlGuard@2024!Strong"

# Enable SSL for production
use_ssl  = true
ssl_mode = "require"

# Use different users for admin and VA
db_username       = "terraform_admin"
sqlguard_username = "sqlguard"
```

### ❌ AVOID:

```hcl
# Don't use postgres superuser
db_username = "postgres"  # ⚠️ Security risk!

# Don't use weak passwords
sqlguard_password = "password123"  # ❌ Will fail validation

# Don't disable SSL in production
use_ssl = false  # ⚠️ Only for dev/test

# Don't use same user for admin and VA
db_username       = "sqlguard"
sqlguard_username = "sqlguard"  # ❌ Will fail validation
```

## PostgreSQL Version Compatibility

| PostgreSQL Version | Status | Notes |
|-------------------|--------|-------|
| 9.x | ⚠️ Limited | Use `postgres` user directly, no sqlguard needed |
| 10.x - 12.x | ✅ Supported | Full VA functionality |
| 13.x - 15.x | ✅ Supported | Full VA functionality |
| 16.x | ✅ Tested | Tested with 16.11 |

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| db_host | Hostname or IP address of PostgreSQL | string | - | yes |
| db_port | PostgreSQL port | number | 5432 | no |
| db_name | Database name to connect to | string | postgres | no |
| db_username | Admin username (must have SUPERUSER) | string | - | yes |
| db_password | Admin user password | string | - | yes |
| sqlguard_username | Guardium VA username | string | sqlguard | no |
| sqlguard_password | Guardium VA user password | string | - | yes |
| use_ssl | Enable SSL for connections | bool | false | no |
| ssl_mode | SSL mode (disable/require/verify-ca/verify-full) | string | disable | no |
| tags | Tags for documentation | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for Guardium VA |
| sqlguard_password | Password for sqlguard user (sensitive) |
| db_host | PostgreSQL hostname |
| db_port | PostgreSQL port |
| db_name | PostgreSQL database name |
| connection_string | Connection string for Guardium |
| va_config_completed | VA configuration status |
| gdmmonitor_group_created | Group creation status |

## What This Module Creates

1. **sqlguard User**: 
   - LOGIN privilege
   - ENCRYPTED password (scram-sha-256)
   - NO SUPERUSER, NO CREATEDB, NO CREATEROLE
   - CONNECT permission on specified database

2. **gdmmonitor Group**:
   - Contains sqlguard user
   - Has `pg_read_all_settings` privilege
   - Required for VA configuration tests

## SSL Configuration and Testing

### SSL Modes Explained

PostgreSQL supports several SSL modes:

| SSL Mode | Description | Use Case |
|----------|-------------|----------|
| `disable` | No SSL encryption | Development/testing only |
| `prefer` | Try SSL, fallback to non-SSL | Self-signed certificates |
| `require` | Require SSL, don't verify certificate | Basic encryption |
| `verify-ca` | Require SSL, verify CA certificate | Production with CA |
| `verify-full` | Require SSL, verify CA and hostname | Maximum security |

### Testing SSL Connection

#### 1. Check if PostgreSQL has SSL Enabled

```bash
# Connect to PostgreSQL and check SSL status
sudo -u postgres psql -c "SHOW ssl;"
# Should show: on

# Check SSL certificate files exist
ls -la /var/lib/pgsql/data/server.{crt,key}
```

#### 2. Test SSL Connection from Client

```bash
# Test with prefer mode (works with self-signed certs)
PGPASSWORD='YourPassword' PGSSLMODE=prefer psql \
  -h api.rr1.cp.fyre.ibm.com \
  -U sqlguard \
  -d postgres \
  -c "SELECT version();"

# Test with require mode (enforces SSL)
PGPASSWORD='YourPassword' PGSSLMODE=require psql \
  -h api.rr1.cp.fyre.ibm.com \
  -U sqlguard \
  -d postgres \
  -c "SELECT version();"

# Verify SSL is being used
PGPASSWORD='YourPassword' PGSSLMODE=require psql \
  -h api.rr1.cp.fyre.ibm.com \
  -U sqlguard \
  -d postgres \
  -c "SELECT ssl_is_used();"
# Should return: t (true)
```

#### 3. Test Connection Timeout

```bash
# Test with connection timeout (30 seconds)
PGPASSWORD='YourPassword' \
PGSSLMODE=prefer \
PGCONNECT_TIMEOUT=30 \
psql -h api.rr1.cp.fyre.ibm.com -U sqlguard -d postgres -c "SELECT 1;"
```

### SSL Certificate Setup

#### For Self-Signed Certificates (Development)

```bash
# On PostgreSQL server, generate self-signed certificate
cd /var/lib/pgsql/data
sudo -u postgres openssl req -new -x509 -days 365 -nodes \
  -text -out server.crt -keyout server.key \
  -subj "/CN=api.rr1.cp.fyre.ibm.com"

# Set proper permissions
sudo chmod 600 server.key
sudo chown postgres:postgres server.{crt,key}

# Enable SSL in postgresql.conf
sudo -u postgres psql -c "ALTER SYSTEM SET ssl = on;"
sudo systemctl restart postgresql
```

#### For CA-Signed Certificates (Production)

```bash
# Copy your CA-signed certificates
sudo cp your-server.crt /var/lib/pgsql/data/server.crt
sudo cp your-server.key /var/lib/pgsql/data/server.key
sudo cp your-ca.crt /var/lib/pgsql/data/root.crt

# Set permissions
sudo chmod 600 /var/lib/pgsql/data/server.key
sudo chown postgres:postgres /var/lib/pgsql/data/server.{crt,key}
sudo chown postgres:postgres /var/lib/pgsql/data/root.crt

# Enable SSL
sudo -u postgres psql -c "ALTER SYSTEM SET ssl = on;"
sudo systemctl restart postgresql
```

### Verifying SSL in Terraform

After running `terraform apply`, verify SSL is working:

```bash
# Check the connection string output
terraform output connection_string
# Should show: postgresql://sqlguard@host:5432/postgres?sslmode=require

# Test the connection using Terraform outputs
PGPASSWORD=$(terraform output -raw sqlguard_password) \
PGSSLMODE=prefer \
psql -h $(terraform output -raw db_host) \
     -p $(terraform output -raw db_port) \
     -U $(terraform output -raw sqlguard_username) \
     -d $(terraform output -raw db_name) \
     -c "SELECT ssl_is_used(), version();"
```

### SSL Troubleshooting

#### Error: "SSL connection has been closed unexpectedly"

```bash
# Check PostgreSQL logs
sudo tail -f /var/lib/pgsql/data/log/postgresql-*.log

# Verify certificate permissions
ls -la /var/lib/pgsql/data/server.{crt,key}
# server.key should be 600 (rw-------)

# Check if SSL is enabled
sudo -u postgres psql -c "SHOW ssl;"
```

#### Error: "certificate verify failed"

```bash
# Use 'prefer' mode instead of 'require' for self-signed certs
ssl_mode = "prefer"

# Or disable certificate verification (not recommended for production)
ssl_mode = "require"  # Requires SSL but doesn't verify certificate
```

#### Error: "Connection timeout"

```bash
# Increase connection timeout
PGCONNECT_TIMEOUT=60 psql -h hostname -U username -d postgres

# Check network connectivity
telnet api.rr1.cp.fyre.ibm.com 5432

# Check firewall rules
sudo firewall-cmd --list-ports | grep 5432
```

## Troubleshooting

### Connection Refused

```bash
# Check if PostgreSQL is listening on all interfaces
sudo -u postgres psql -c "SHOW listen_addresses;"
# Should show: *

# Check if firewall allows port 5432
sudo firewall-cmd --list-ports | grep 5432

# Test basic connectivity
telnet api.rr1.cp.fyre.ibm.com 5432
```

### Authentication Failed

```bash
# Check pg_hba.conf has remote access rule
sudo cat /var/lib/pgsql/data/pg_hba.conf | grep "0.0.0.0/0"
# Should show: host    all    all    0.0.0.0/0    scram-sha-256

# Test connection manually
PGPASSWORD='YourPassword' psql -h hostname -U username -d postgres -c "SELECT version();"

# Check password encryption method
sudo -u postgres psql -c "SHOW password_encryption;"
# Should show: scram-sha-256
```

### Password Policy Errors

The module enforces strong passwords. Ensure your password has:
- At least 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

Example: `SqlGuard@2024!Strong`

### User Already Exists

The module is idempotent - it checks if users exist before creating them. If you see "already exists" messages, this is normal and not an error.

## Security Considerations

- **Least Privilege**: sqlguard user has minimal required permissions
- **Password Encryption**: Uses scram-sha-256 (PostgreSQL 10+)
- **SSL Support**: Optional TLS encryption for connections
- **User Separation**: Enforces different users for admin and VA operations
- **No Hardcoded Credentials**: All passwords are variables

## Examples

See the [examples/onprem-postgresql](../../examples/onprem-postgresql) directory for complete working examples.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| null | >= 3.0 |

## License

```text
#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#
```

## Support

For issues and questions:
- Create an issue in the repository
- Contact the maintainers

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [IBM Guardium Data Protection](https://www.ibm.com/docs/en/guardium)
- [Guardium VA Guide](https://www.ibm.com/docs/en/guardium/12.2?topic=assessment-vulnerability)