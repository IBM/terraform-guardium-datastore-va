#!/bin/bash
# Script to set up Guardium VA configuration for PostgreSQL

# Check if psql command is available
if ! command -v psql &> /dev/null; then
    echo "Error: PostgreSQL client (psql) is not installed or not in PATH"
    echo "Please install PostgreSQL client before running this script"
    echo "For example:"
    echo "  - On Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  - On RHEL/CentOS/Amazon Linux: sudo yum install postgresql"
    echo "  - On macOS with Homebrew: brew install postgresql"
    exit 1
fi

# Check if environment variables are set
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ] || [ -z "$SQLGUARD_PASSWORD" ]; then
    echo "Error: Required environment variables are not set"
    echo "Required: DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASSWORD, SQLGUARD_PASSWORD"
    exit 1
fi

# Set default values for optional variables
SQLGUARD_USERNAME=${SQLGUARD_USERNAME:-"sqlguard"}
VA_CONFIG_SCRIPT=${VA_CONFIG_SCRIPT:-"aws-rds-postgres-va-config.sql"}

echo "Setting up Guardium VA configuration for PostgreSQL..."
echo "Database: $DB_NAME on $DB_HOST:$DB_PORT"
echo "Creating user: $SQLGUARD_USERNAME"

# Create a temporary SQL file for setting up the sqlguard user
cat > /tmp/setup_sqlguard.sql << EOF
-- Create sqlguard user if it doesn't exist
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$SQLGUARD_USERNAME') THEN
        CREATE ROLE $SQLGUARD_USERNAME LOGIN
        ENCRYPTED PASSWORD '$SQLGUARD_PASSWORD'
        NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
    END IF;
END
\$\$;

-- Create gdmmonitor group and add sqlguard to it
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gdmmonitor') THEN
        CREATE GROUP gdmmonitor;
    END IF;
END
\$\$;

-- Add sqlguard to gdmmonitor group
ALTER GROUP gdmmonitor ADD USER $SQLGUARD_USERNAME;

-- Grant necessary permissions
GRANT pg_read_all_settings TO gdmmonitor;

-- Grant CONNECT privilege to sqlguard
GRANT CONNECT ON DATABASE $DB_NAME TO $SQLGUARD_USERNAME;

-- Grant USAGE on schema public to sqlguard
GRANT USAGE ON SCHEMA public TO $SQLGUARD_USERNAME;

-- Grant SELECT on all tables in public schema to sqlguard
GRANT SELECT ON ALL TABLES IN SCHEMA public TO $SQLGUARD_USERNAME;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO $SQLGUARD_USERNAME;
EOF

# Execute the SQL file to set up the sqlguard user
export PGPASSWORD="$DB_PASSWORD"
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USERNAME" -f /tmp/setup_sqlguard.sql

# Check if the setup was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to set up sqlguard user"
    exit 1
fi

echo "sqlguard user set up successfully"

# Execute the VA configuration script
echo "Running VA configuration script..."
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USERNAME" -f "$VA_CONFIG_SCRIPT"

# Check if the VA configuration was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to run VA configuration script"
    exit 1
fi

echo "VA configuration completed successfully"

# Clean up
rm -f /tmp/setup_sqlguard.sql

exit 0
