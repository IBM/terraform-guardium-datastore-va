#!/bin/bash

# ============================================================================
# Oracle VA User Setup Script
# ============================================================================
# This script connects to Oracle RDS and creates the sqlguard user
# for Guardium Vulnerability Assessment
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================================"
echo "Oracle VA User Setup"
echo "============================================================================"
echo ""

# Database connection details from terraform.tfvars
DB_HOST="nexus-oracle-rds.c1wbwkkrn7x2.us-east-2.rds.amazonaws.com"
DB_PORT="1521"
DB_SERVICE="ORCL"
DB_ADMIN_USER="admin"
DB_ADMIN_PASS="OracleAdmin123!"

echo "📋 Connection Details:"
echo "   Host: $DB_HOST"
echo "   Port: $DB_PORT"
echo "   Service: $DB_SERVICE"
echo "   Admin User: $DB_ADMIN_USER"
echo ""

# Check if sqlplus is installed
if ! command -v sqlplus &> /dev/null; then
    echo -e "${RED}❌ ERROR: Oracle SQL*Plus client not found${NC}"
    echo ""
    echo "Please install Oracle Instant Client:"
    echo ""
    echo "macOS:"
    echo "  brew install instantclient-sqlplus"
    echo ""
    echo "Linux:"
    echo "  Download from: https://www.oracle.com/database/technologies/instant-client/downloads.html"
    echo ""
    echo "Alternative: Run this SQL script manually in Oracle SQL Developer or another Oracle client"
    echo "  File: create-sqlguard-user.sql"
    exit 1
fi

echo "🔌 Testing connection to Oracle database..."
echo ""

# Test connection
if echo "SELECT 'Connection successful' FROM DUAL;" | sqlplus -S "$DB_ADMIN_USER/$DB_ADMIN_PASS@//$DB_HOST:$DB_PORT/$DB_SERVICE" | grep -q "Connection successful"; then
    echo -e "${GREEN}✅ Connection successful${NC}"
    echo ""
else
    echo -e "${RED}❌ Connection failed${NC}"
    echo ""
    echo "Please verify:"
    echo "  1. Oracle database is running"
    echo "  2. Security group allows your IP"
    echo "  3. Admin credentials are correct"
    exit 1
fi

echo "👤 Creating sqlguard user..."
echo ""

# Run the SQL script
sqlplus -S "$DB_ADMIN_USER/$DB_ADMIN_PASS@//$DB_HOST:$DB_PORT/$DB_SERVICE" @create-sqlguard-user.sql

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ SUCCESS: sqlguard user created successfully${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Test connection in Guardium UI"
    echo "  2. Datasource: nexus-oracle-rds-local"
    echo "  3. Username: sqlguard"
    echo "  4. Password: SqlGuard456!"
    echo ""
else
    echo ""
    echo -e "${RED}❌ ERROR: Failed to create sqlguard user${NC}"
    echo ""
    echo "Check the error messages above for details"
    exit 1
fi

# Made with Bob
