# Azure PostgreSQL Flexible Server VA Configuration Module

This Terraform module configures Vulnerability Assessment (VA) for Azure PostgreSQL Flexible Server by creating the necessary Azure infrastructure.

## Overview

This module creates:
- Azure Key Vault for storing database credentials
- Azure Function App infrastructure for VA configuration
- Storage Account for Azure Function
- App Service Plan (Elastic Premium EP1 for VNet integration)
- Managed Identity for secure access
- Firewall rules for Guardium connectivity

## Prerequisites

- Azure PostgreSQL Flexible Server already deployed
- Azure CLI authenticated
- Terraform >= 1.0
- Appropriate Azure permissions to create resources

## Usage

```hcl
module "azure_postgresql_va_config" {
  source = "../../modules/azure-postgresql"

  name_prefix         = "my-app"
  resource_group_name = "my-resource-group"
  location            = "canadacentral"

  # Database Connection Details
  db_host     = "my-postgresql-server.postgres.database.azure.com"
  db_port     = 5432
  db_name     = "mydatabase"
  db_username = "pgadmin"
  db_password = var.db_password

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # Guardium Server Configuration (for automatic firewall rules)
  guardium_hostname       = "guardium.example.com"  # Will be resolved to IP
  postgresql_server_name  = "my-postgresql-server"
  enable_public_access    = true  # Enable public access for Guardium connectivity

  # Additional firewall rules for corporate networks
  additional_firewall_rules = {
    "AllowCorporateNetwork" = {
      start_ip = "10.0.0.0"
      end_ip   = "10.255.255.255"
    }
  }

  # VNet Configuration (for Function App)
  vnet_name                      = "my-vnet"
  function_subnet_address_prefix = "10.0.2.0/24"

  tags = {
    Environment = "production"
    Purpose     = "guardium-va"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| resource_group_name | Azure resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| db_host | PostgreSQL server FQDN | `string` | n/a | yes |
| db_port | PostgreSQL server port | `number` | `5432` | no |
| db_name | Database name | `string` | n/a | yes |
| db_username | Admin username | `string` | n/a | yes |
| db_password | Admin password | `string` | n/a | yes |
| sqlguard_username | Guardium VA username | `string` | `"sqlguard"` | no |
| sqlguard_password | Guardium VA password | `string` | n/a | yes |
| guardium_hostname | Guardium server hostname (resolved to IP) | `string` | `""` | no |
| postgresql_server_name | Azure PostgreSQL server name | `string` | `""` | no |
| enable_public_access | Enable public access for Guardium | `bool` | `false` | no |
| vnet_name | Existing VNet name | `string` | n/a | yes |
| function_subnet_address_prefix | Function subnet CIDR | `string` | n/a | yes |
| additional_firewall_rules | Additional firewall rules | `map(object)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Deployment Modes

This module supports two deployment modes for Guardium connectivity:

### Mode 1: Private Access (Production - Recommended)

**Use Case**: Production environments requiring maximum security

**Configuration**:
```hcl
module "azure_postgresql_va" {
  source = "../../modules/azure-postgresql"
  
  # ... other required variables ...
  
  enable_public_access = false  # Default - no public access
  # guardium_hostname and postgresql_server_name not required
}
```

**Requirements**:
- PostgreSQL server deployed with VNet integration (private access only)
- Guardium connects via **Azure Private Link** or **VPN/ExpressRoute**
- Azure Function connects via VNet integration (already configured)
- No firewall rules created - all traffic stays private

**Benefits**:
- ✅ Maximum security - no public internet exposure
- ✅ Compliant with enterprise security policies
- ✅ No firewall management needed

---

### Mode 2: Public Access with Firewall (Testing/Demo)

**Use Case**: Testing, demos, or environments where Private Link/VPN is not available

**Configuration**:
```hcl
module "azure_postgresql_va" {
  source = "../../modules/azure-postgresql"
  
  # ... other required variables ...
  
  # Enable public access mode
  enable_public_access    = true
  guardium_hostname       = "guardium.example.com"  # Resolved to IP automatically
  postgresql_server_name  = azurerm_postgresql_flexible_server.postgresql_server.name
}
```

**Requirements**:
- PostgreSQL server must have `public_network_access_enabled = true`
- Guardium hostname must be resolvable via DNS
- Azure Function still uses VNet integration

**How It Works**:
1. Module resolves `guardium_hostname` to IP using DNS lookup
2. Creates firewall rule allowing only that specific IP
3. Creates firewall rule for Azure services (Function App)

**Benefits**:
- ✅ Automatic IP resolution - no manual lookup needed
- ✅ Restricted access - only Guardium IP allowed
- ✅ Easy testing without VPN setup

**Security Note**: While firewall-restricted, public access is less secure than Private Link. Use only for testing/demo environments.

---

## Automatic Guardium Firewall Configuration

When `enable_public_access = true`, the module automatically:

1. **DNS Resolution**: Resolves `guardium_hostname` to public IP
   ```hcl
   data "dns_a_record_set" "guardium_ip" {
     host = var.guardium_hostname
   }
   ```

2. **Firewall Rules**: Creates PostgreSQL firewall rules:
   - **AllowGuardiumServer**: Specific Guardium IP only
   - **AllowAzureServices**: Azure Function App access

3. **Dynamic Updates**: Re-run Terraform if Guardium IP changes

## Outputs

| Name | Description |
|------|-------------|
| function_app_name | Name of the Azure Function App |
| function_app_id | ID of the Azure Function App |
| function_app_default_hostname | Default hostname of the Function App |
| key_vault_name | Name of the Key Vault |
| key_vault_id | ID of the Key Vault |
| sqlguard_username | Guardium VA username |
| guardium_resolved_ip | Resolved IP address of Guardium server |
| firewall_rules_created | Status of firewall rule creation |
| va_config_completed | Status message |

## What Gets Created

### Azure Key Vault
- Stores PostgreSQL credentials securely
- Soft delete enabled (7 days retention)
- Access policies for Function App

### Azure Function App
- Linux-based Function App
- Python 3.9 runtime
- Elastic Premium (EP1) plan for VNet integration
- System-assigned managed identity
- Integrated with Key Vault

### Storage Account
- Standard LRS replication
- Used by Azure Function

## Security

- Credentials stored in Azure Key Vault
- Managed Identity for Function App authentication
- No hardcoded secrets in code
- Soft delete enabled on Key Vault

## Function Code Deployment

This module creates the infrastructure and deploys the function code automatically using Azure CLI.

The function:
1. Retrieves credentials from Key Vault
2. Connects to PostgreSQL server
3. Creates `sqlguard` user with appropriate permissions
4. Configures database for VA scanning

Example permissions for sqlguard user:
```sql
CREATE USER sqlguard WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE mydatabase TO sqlguard;
GRANT USAGE ON SCHEMA public TO sqlguard;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO sqlguard;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO sqlguard;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO sqlguard;
GRANT SELECT ON pg_catalog.pg_user TO sqlguard;
GRANT SELECT ON pg_catalog.pg_database TO sqlguard;
```

## Cost Considerations

- **Key Vault**: ~$0.03/10,000 operations
- **Function App (EP1)**: ~$150/month (includes VNet integration)
- **Storage Account**: ~$0.02/GB/month

**Estimated monthly cost**: ~$150-160 for typical usage

## Limitations

- Requires Azure CLI for function deployment
- Key Vault name must be globally unique (handled by name_prefix)
- Storage Account name must be globally unique (handled by name_prefix)

## Example

See the [examples/azure-postgresql](../../examples/azure-postgresql) directory for a complete working example.

## Troubleshooting

### Connection Test Hangs in Guardium UI

**Symptom**: When testing the connection in Guardium UI, the test hangs indefinitely without completing.

**Common Causes**:

1. **Corporate Network/Firewall Blocking Outbound PostgreSQL Connections**
   - Many corporate networks block outbound connections on port 5432
   - The Guardium server may be behind a corporate proxy or firewall
   
   **Solution**: Add additional firewall rules for your corporate network range:
   ```hcl
   additional_firewall_rules = {
     "AllowCorporateNetwork" = {
       start_ip = "10.0.0.0"
       end_ip   = "10.255.255.255"
     }
   }
   ```

2. **Guardium Server Uses Different Outbound IP**
   - The `guardium_hostname` resolves to an internal IP (e.g., 9.46.196.79)
   - But the server uses a NAT gateway with a different public IP for outbound connections
   
   **Solution**: Find the actual outbound IP and add it:
   ```hcl
   additional_firewall_rules = {
     "AllowGuardiumNATGateway" = {
       start_ip = "203.0.113.10"  # Replace with actual outbound IP
       end_ip   = "203.0.113.10"
     }
   }
   ```

3. **DNS Resolution Issues**
   - The Guardium server cannot resolve the Azure PostgreSQL FQDN
   
   **Solution**: Verify DNS resolution from Guardium server:
   ```bash
   nslookup your-postgresql-server.postgres.database.azure.com
   ```

4. **Temporary Workaround: Allow All IPs (Testing Only)**
   - **⚠️ WARNING**: This is insecure and should only be used temporarily for diagnosis
   
   ```hcl
   additional_firewall_rules = {
     "TemporaryAllowAll" = {
       start_ip = "0.0.0.1"
       end_ip   = "255.255.255.255"
     }
   }
   ```
   
   If this works, the issue is firewall-related. Find the correct IP range and restrict access.

### Function App Permission Errors

**Symptom**: Function execution fails with "does not have secrets get permission on key vault"

**Solution**: The module automatically creates the Key Vault access policy, but if you see this error:

1. Verify the Function App's Managed Identity is enabled:
   ```bash
   az functionapp identity show --name <function-app-name> --resource-group <rg-name>
   ```

2. Manually grant permissions if needed:
   ```bash
   az keyvault set-policy --name <key-vault-name> \
     --object-id <function-app-principal-id> \
     --secret-permissions get list
   ```

### Import Errors During Terraform Apply

**Symptom**: "A resource with the ID ... already exists - to be managed via Terraform this resource needs to be imported"

**Cause**: Resources were created manually or by another process before running Terraform.

**Solution**: Import the existing resources:
```bash
# Import firewall rule
terraform import 'module.azure_postgresql_va_config.azurerm_postgresql_flexible_server_firewall_rule.guardium_access[0]' \
  '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/<server>/firewallRules/<rule-name>'

# Import additional firewall rules
terraform import 'module.azure_postgresql_va_config.azurerm_postgresql_flexible_server_firewall_rule.additional_rules["RuleName"]' \
  '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/<server>/firewallRules/RuleName'
```

### Testing Connection from Command Line

To test PostgreSQL connectivity from your local machine or Guardium server:

```bash
# Test basic connectivity
psql -h your-server.postgres.database.azure.com \
  -U sqlguard \
  -d mydatabase \
  -c "SELECT 1 as test;" \
  sslmode=require

# Test with timeout
timeout 10 psql -h your-server.postgres.database.azure.com \
  -U sqlguard \
  -d mydatabase \
  -c "SELECT 1 as test;" \
  sslmode=require
```

If this hangs, the issue is network connectivity, not authentication.

### Verifying Firewall Rules

Check current firewall rules:
```bash
az postgres flexible-server firewall-rule list \
  --resource-group <rg-name> \
  --name <server-name> \
  --output table
```

### Function Invocation for Testing

Manually invoke the Azure Function to test sqlguard user creation:

```bash
# Get function key
FUNCTION_KEY=$(az functionapp function keys list \
  --resource-group <rg-name> \
  --name <function-app-name> \
  --function-name PostgreSQLVAConfig \
  --query "default" -o tsv)

# Invoke function
curl -X POST \
  "https://<function-app-name>.azurewebsites.net/api/PostgreSQLVAConfig?code=$FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected successful response:
```json
{
  "success": true,
  "message": "VA configuration completed successfully",
  "operations": [
    {"operation": "create_sqlguard_user", "status": "success"},
    {"operation": "grant_connect", "status": "success"},
    {"operation": "grant_usage_schema", "status": "success"},
    {"operation": "grant_select_tables", "status": "success"},
    {"operation": "grant_select_sequences", "status": "success"},
    {"operation": "alter_default_privileges", "status": "success"},
    {"operation": "grant_pg_catalog_access", "status": "success"}
  ]
}
```

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
