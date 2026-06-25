# Azure PostgreSQL VA Configuration Function

This directory contains the Azure Function code for configuring PostgreSQL Vulnerability Assessment (VA) users.

## Overview

The Azure Function performs the following tasks:
1. Retrieves PostgreSQL credentials from Azure Key Vault using Managed Identity
2. Connects to the Azure PostgreSQL Flexible Server with SSL
3. Creates or updates the `sqlguard` user for VA scanning
4. Grants required permissions:
   - CONNECT on database
   - USAGE on schema public
   - SELECT on all tables in schema public
   - SELECT on all sequences in schema public
   - ALTER DEFAULT PRIVILEGES for future tables
   - SELECT on pg_catalog system tables

## Files

- `function.zip` - Pre-built Azure Function package ready for deployment
- `README.md` - This documentation file

The function package contains:
- `PostgreSQLVAConfig/__init__.py` - Main function code
- `PostgreSQLVAConfig/function.json` - Function binding configuration
- `requirements.txt` - Python dependencies (psycopg2-binary, azure-identity, azure-keyvault-secrets)
- `host.json` - Function app host configuration

## Deployment

The function is automatically deployed by Terraform using the `null_resource` provisioner with Azure CLI.

The deployment process:
1. Terraform creates the Azure Function App infrastructure
2. Terraform deploys the function code from `function.zip`
3. Terraform invokes the function to configure the VA user

## Manual Deployment

If you need to deploy manually:

```bash
az functionapp deployment source config-zip \
  --resource-group <resource-group-name> \
  --name <function-app-name> \
  --src function.zip
```

## Testing

To test the function manually:

```bash
# Get the function key
FUNCTION_KEY=$(az functionapp keys list \
  --resource-group <resource-group-name> \
  --name <function-app-name> \
  --query "functionKeys.default" -o tsv)

# Invoke the function
curl -X POST "https://<function-app-name>.azurewebsites.net/api/PostgreSQLVAConfig?code=$FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Environment Variables

The function requires the following environment variables (automatically set by Terraform):

- `KEY_VAULT_NAME` - Name of the Azure Key Vault containing credentials
- `SECRET_NAME` - Name of the secret in Key Vault
- `FUNCTIONS_WORKER_RUNTIME` - Set to "python"

## Dependencies

- `azure-functions` - Azure Functions Python SDK
- `azure-identity` - Azure authentication using Managed Identity
- `azure-keyvault-secrets` - Azure Key Vault client
- `psycopg2-binary` - PostgreSQL database connector

## Security

- Uses Azure Managed Identity for authentication (no credentials in code)
- Credentials stored securely in Azure Key Vault
- SSL/TLS encryption for PostgreSQL connections (sslmode=require)
- Function key required for invocation

## Troubleshooting

Check function logs in Azure Portal:
1. Navigate to Function App
2. Go to "Functions" > "PostgreSQLVAConfig"
3. Click "Monitor" to view execution logs

Or use Azure CLI:
```bash
az functionapp logs tail \
  --resource-group <resource-group-name> \
  --name <function-app-name>
```

## PostgreSQL-Specific Notes

### Permissions Granted

The function grants the following permissions to the `sqlguard` user:

```sql
-- Connect to database
GRANT CONNECT ON DATABASE {database_name} TO sqlguard;

-- Schema access
GRANT USAGE ON SCHEMA public TO sqlguard;

-- Table access
GRANT SELECT ON ALL TABLES IN SCHEMA public TO sqlguard;

-- Sequence access
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO sqlguard;

-- Future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO sqlguard;

-- System catalog access
GRANT SELECT ON pg_catalog.pg_user TO sqlguard;
GRANT SELECT ON pg_catalog.pg_database TO sqlguard;
```

### Connection String Format

PostgreSQL connection uses the following format:
```
postgresql://username:password@hostname:5432/database?sslmode=require # pragma: allowlist secret
```

### Differences from MySQL

- Uses `psycopg2-binary` instead of `PyMySQL`
- Default port is 5432 (not 3306)
- Uses `CREATE USER` instead of `CREATE USER '@'%'`
- Uses `GRANT CONNECT` instead of `GRANT USAGE`
- Uses schema-based permissions (public schema)
- Uses `pg_catalog` system tables instead of `mysql.*` tables
