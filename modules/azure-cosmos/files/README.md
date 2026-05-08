# Azure Cosmos DB VA Configuration Function

This directory contains the Azure Function code for configuring Cosmos DB for Guardium Vulnerability Assessment.

## Function Package

The `function.zip` file contains:
- Python Azure Function code
- Dependencies (azure-cosmos, azure-identity, etc.)
- Function configuration (function.json, host.json)

## Function Purpose

The function performs the following tasks:
1. Retrieves Cosmos DB credentials from Azure Key Vault
2. Connects to the Cosmos DB account
3. Configures VA-specific settings and permissions
4. Returns configuration status

## Rebuilding the Function

If you need to modify the function code:

1. Extract the function.zip
2. Modify the Python code as needed
3. Update requirements.txt if adding dependencies
4. Rebuild the package:
   ```bash
   cd function_code
   pip install -r requirements.txt -t .
   zip -r ../function.zip .
   ```

## Function Invocation

The function is automatically deployed by Terraform. To manually invoke:

```bash
# Get function key
FUNC_KEY=$(az functionapp keys list \
  --resource-group <resource-group> \
  --name <function-name> \
  --query "functionKeys.default" -o tsv)

# Invoke function
curl -X POST \
  "https://<function-name>.azurewebsites.net/api/CosmosVAConfig?code=$FUNC_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Environment Variables

The function uses these environment variables (set by Terraform):
- `KEY_VAULT_NAME`: Name of the Key Vault containing credentials
- `SECRET_NAME`: Name of the secret with Cosmos DB connection details
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0