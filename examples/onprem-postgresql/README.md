# On-Premise PostgreSQL Vulnerability Assessment Example

This example demonstrates how to configure an on-premise PostgreSQL database for IBM Guardium Vulnerability Assessment (VA).

## Overview

This example:
- Creates a `sqlguard` user for Guardium VA scanning
- Creates a `gdmmonitor` group with required permissions
- Configures the database for security assessments
- Validates configuration before deployment
- Supports SSL/TLS connections

## Prerequisites

### 1. PostgreSQL Server Requirements

- PostgreSQL 10.x or above (tested with 16.11)
- Admin user with SUPERUSER privileges
- Remote connections enabled
- Port 5432 accessible

### 2. PostgreSQL Server Configuration

Your PostgreSQL server must be configured for remote access. Run these commands on the server:

```bash
# 1. Configure PostgreSQL to listen on all interfaces
sudo -u postgres psql -c "ALTER SYSTEM SET listen_addresses = '*';"

# 2. Enable password encryption
sudo -u postgres psql -c "ALTER SYSTEM SET password_encryption = 'scram-sha-256';"

# 3. Add remote access rule to pg_hba.conf
echo "host    all             all             0.0.0.0/0               scram-sha-256" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf

# 4. Restart PostgreSQL
sudo systemctl restart postgresql

# 5. Open firewall port
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload

# 6. Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'YourSecurePassword';"
```

### 3. Local Machine Requirements

- Terraform >= 1.0.0
- `psql` client installed
- Network connectivity to PostgreSQL server

Install psql client:
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# RHEL/CentOS
sudo yum install postgresql
```

## Usage

### Step 1: Copy Configuration File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit terraform.tfvars

Update with your PostgreSQL details:

```hcl
# PostgreSQL Database Connection
db_host     = "your-postgres-server.example.com"
db_port     = 5432
db_name     = "postgres"
db_username = "postgres"
db_password = "YourAdminPassword"

# Guardium VA User
sqlguard_username = "sqlguard"
sqlguard_password = "SqlGuard@2024!Strong"

# SSL Configuration
use_ssl  = false  # Set to true for production
ssl_mode = "disable"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Validate Configuration

```bash
terraform validate
```

### Step 5: Preview Changes

```bash
terraform plan
```

This will show you:
- ✅ All 6 validation checks passing
- What users/groups will be created
- What permissions will be granted

### Step 6: Apply Configuration

```bash
terraform apply
```

Review the plan and type `yes` to proceed.

### Step 7: Verify Configuration

```bash
# Test connection with sqlguard user
PGPASSWORD='SqlGuard@2024!Strong' psql \
  -h your-postgres-server.example.com \
  -U sqlguard \
  -d postgres \
  -c "SELECT version();"

# Check user and group
PGPASSWORD='YourAdminPassword' psql \
  -h your-postgres-server.example.com \
  -U postgres \
  -d postgres \
  -c "SELECT rolname, rolsuper, rolinherit FROM pg_roles WHERE rolname IN ('sqlguard', 'gdmmonitor');"
```

## What Gets Created

### 1. sqlguard User
```sql
CREATE ROLE sqlguard LOGIN
ENCRYPTED PASSWORD 'SqlGuard@2024!Strong'
NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
```

### 2. gdmmonitor Group
```sql
CREATE GROUP gdmmonitor;
ALTER GROUP gdmmonitor ADD USER sqlguard;
GRANT pg_read_all_settings TO gdmmonitor;
```

### 3. Database Permissions
```sql
GRANT CONNECT ON DATABASE postgres TO sqlguard;
```

## Configuration Options

### Development/Testing (No SSL)

```hcl
use_ssl  = false
ssl_mode = "disable"
```

### Production (With SSL)

```hcl
use_ssl  = true
ssl_mode = "require"  # or "verify-ca" or "verify-full"
```

## Validation Checks

The module performs 6 validation checks during `terraform plan`:

1. ✅ **Admin User Security**: Warns if using `postgres` superuser
2. ✅ **Password Strength**: Enforces strong password requirements
3. ✅ **User Separation**: Ensures sqlguard ≠ admin user
4. ✅ **SSL Configuration**: Validates SSL mode settings
5. ✅ **Port Validation**: Checks port is valid (1-65535)
6. ✅ **Hostname Format**: Validates hostname/IP format

## Troubleshooting

### Connection Refused

```bash
# Check if PostgreSQL is listening
sudo netstat -tlnp | grep 5432

# Should show: 0.0.0.0:5432

# If not, check listen_addresses
sudo -u postgres psql -c "SHOW listen_addresses;"
```

### Authentication Failed

```bash
# Check pg_hba.conf
sudo cat /var/lib/pgsql/data/pg_hba.conf | grep "0.0.0.0/0"

# Should show:
# host    all    all    0.0.0.0/0    scram-sha-256

# Test connection manually
PGPASSWORD='YourPassword' psql -h hostname -U postgres -d postgres -c "SELECT 1;"
```

### Password Policy Errors

Ensure your password meets requirements:
- ✓ At least 8 characters
- ✓ At least one uppercase letter
- ✓ At least one lowercase letter
- ✓ At least one number
- ✓ At least one special character

Example: `SqlGuard@2024!Strong`

### Firewall Issues

```bash
# Check if port is open
sudo firewall-cmd --list-ports | grep 5432

# If not, add it
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

## Outputs

After successful deployment, you'll see:

```
Outputs:

connection_string = "postgresql://sqlguard@your-server:5432/postgres"
db_host = "your-server.example.com"
db_port = 5432
sqlguard_username = "sqlguard"
va_config_completed = true
```

## Clean Up

To remove the sqlguard user and gdmmonitor group:

```bash
# Connect as admin
PGPASSWORD='YourAdminPassword' psql \
  -h your-server.example.com \
  -U postgres \
  -d postgres \
  -c "DROP ROLE IF EXISTS sqlguard; DROP ROLE IF EXISTS gdmmonitor;"
```

Then destroy Terraform state:

```bash
terraform destroy
```

## Security Best Practices

1. **Use Strong Passwords**: Follow the password policy requirements
2. **Enable SSL**: Use SSL for production environments
3. **Dedicated Admin User**: Create a dedicated admin user instead of using `postgres`
4. **Least Privilege**: sqlguard user has minimal required permissions
5. **Secure Credentials**: Store passwords in environment variables or secret managers

## Next Steps

After configuring the database:

1. Register the datasource in Guardium Data Protection
2. Configure vulnerability assessment schedules
3. Set up email notifications for assessment results
4. Review and remediate findings

## Support

For issues:
- Check the [module README](../../modules/onprem-postgresql/README.md)
- Review [troubleshooting guide](../../modules/onprem-postgresql/README.md#troubleshooting)
- Create an issue in the repository

## License

```text
#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#