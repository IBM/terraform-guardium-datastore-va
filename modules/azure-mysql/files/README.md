# Azure MySQL VA Configuration Function

This directory contains the Azure Function code for configuring MySQL Vulnerability Assessment (VA) users.

## Overview

The Azure Function performs the following tasks:
1. Retrieves MySQL credentials from Azure Key Vault using Managed Identity
2. Connects to the Azure MySQL Flexible Server with SSL
3. Creates or updates the `sqlguard` user for VA scanning
4. Grants required permissions:
   - SELECT on mysql.user
   - SELECT on mysql.db
   - SHOW DATABASES on *.*

## Files

- `function.zip` - Pre-built Azure Function package ready for deployment
- `README.md` - This documentation file

The function package contains:
- `MySQLVAConfig/__init__.py` - Main function code
- `MySQLVAConfig/function.json` - Function binding configuration
- `requirements.txt` - Python dependencies (PyMySQL, azure-identity, azure-keyvault-secrets)
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
curl -X POST "https://<function-app-name>.azurewebsites.net/api/MySQLVAConfig?code=$FUNCTION_KEY" \
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
- `PyMySQL` - MySQL database connector

## Security

- Uses Azure Managed Identity for authentication (no credentials in code)
- Credentials stored securely in Azure Key Vault
- SSL/TLS encryption for MySQL connections
- Function key required for invocation

## Troubleshooting

Check function logs in Azure Portal:
1. Navigate to Function App
2. Go to "Functions" > "MySQLVAConfig"
3. Click "Monitor" to view execution logs

Or use Azure CLI:
```bash
az functionapp logs tail \
  --resource-group <resource-group-name> \
  --name <function-app-name>