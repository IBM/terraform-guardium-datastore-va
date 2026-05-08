# Azure Cosmos DB Vulnerability Assessment Configuration Module

This Terraform module configures Azure Cosmos DB for Guardium Vulnerability Assessment (VA) by:

1. Creating an Azure Key Vault to securely store Cosmos DB credentials
2. Deploying an Azure Function to configure VA settings
3. Setting up VNet integration for secure connectivity
4. Configuring firewall rules for Guardium access (optional)

## Features

- **Secure Credential Storage**: Uses Azure Key Vault to store Cosmos DB connection details and keys
- **Automated Configuration**: Azure Function automates the VA configuration process
- **VNet Integration**: Function App integrates with existing VNet for secure database access
- **Flexible Access Control**: Supports both public and private network access patterns
- **Multi-API Support**: Works with both SQL API (GlobalDocumentDB) and MongoDB API

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.0
- Existing Azure Cosmos DB account
- Existing VNet with available subnet space for Function App

## Usage

```hcl
module "azure_cosmos_va" {
  source = "../../terraform-guardium-datastore-va/modules/azure-cosmos"

  cosmos_account_name     = "my-cosmos-account"
  cosmos_account_endpoint = "https://my-cosmos-account.documents.azure.com:443/"
  cosmos_db_kind          = "GlobalDocumentDB"  # or "MongoDB"
  database_name           = "mydb"
  resource_group_name     = "my-resource-group"
  location                = "eastus"
  name_prefix             = "guardium"
  
  # Guardium Configuration
  enable_public_access = true
  guardium_hostname    = "guardium.example.com"
  guardium_ip_address  = "1.2.3.4/32"
  
  # VNet Configuration
  vnet_name                      = "my-vnet"
  function_subnet_address_prefix = "10.0.2.0/24"
  
  tags = {
    Environment = "production"
    Purpose     = "guardium-va"
  }
}
```

## Network Access Patterns

### Public Access (Development/Testing)
Set `enable_public_access = true` and provide `guardium_ip_address`. The module will:
- Add Guardium IP to Cosmos DB firewall rules
- Allow Function App to access Cosmos DB via public endpoint

### Private Access (Production)
Set `enable_public_access = false`. You must configure:
- Azure Private Link for Cosmos DB
- VPN or ExpressRoute for Guardium connectivity
- Appropriate network security groups

## Cosmos DB API Support

### SQL API (GlobalDocumentDB)
```hcl
cosmos_db_kind = "GlobalDocumentDB"
```
Use for document-based NoSQL workloads with SQL-like queries.

### MongoDB API
```hcl
cosmos_db_kind = "MongoDB"
```
Use for MongoDB-compatible workloads.

## Function Deployment

The module automatically deploys the Azure Function code using Azure CLI. The function:
1. Retrieves Cosmos DB credentials from Key Vault
2. Configures VA settings in the Cosmos DB account
3. Returns configuration status

To manually invoke the function after deployment:
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cosmos_account_name | Name of the Azure Cosmos DB account | string | n/a | yes |
| cosmos_account_endpoint | Endpoint URL of the Cosmos DB account | string | n/a | yes |
| cosmos_db_kind | API kind (GlobalDocumentDB or MongoDB) | string | n/a | yes |
| database_name | Name of the Cosmos DB database | string | n/a | yes |
| resource_group_name | Name of the Azure resource group | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| name_prefix | Prefix for resource names | string | n/a | yes |
| vnet_name | Name of the existing VNet | string | n/a | yes |
| function_subnet_address_prefix | Address prefix for Function subnet | string | n/a | yes |
| guardium_hostname | Hostname of Guardium server | string | "" | no |
| guardium_ip_address | IP address of Guardium (CIDR) | string | "" | no |
| enable_public_access | Enable public network access | bool | false | no |
| additional_firewall_ips | Additional IPs for firewall | list(string) | [] | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| function_app_name | Name of the Azure Function App |
| function_app_id | ID of the Azure Function App |
| key_vault_name | Name of the Key Vault |
| cosmos_account_name | Name of the Cosmos DB account |
| connection_info | Connection information for Guardium |
| va_config_completed | Status message |

## Security Considerations

1. **Credential Management**: All credentials are stored in Azure Key Vault
2. **Network Isolation**: Use VNet integration and Private Link for production
3. **Access Control**: Function App uses Managed Identity for Key Vault access
4. **Firewall Rules**: Restrict IP access to known Guardium servers only
5. **Encryption**: Cosmos DB data is encrypted at rest and in transit

## Troubleshooting

### Function Deployment Issues
- Ensure Azure CLI is authenticated: `az login`
- Check Function App logs in Azure Portal
- Verify Key Vault access policies

### Connectivity Issues
- Verify firewall rules in Cosmos DB
- Check VNet integration status
- Ensure Guardium can resolve Cosmos DB endpoint

### Permission Issues
- Verify Function App Managed Identity has Key Vault access
- Check Cosmos DB account permissions

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0