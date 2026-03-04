# Azure MySQL Flexible Server VA Configuration Module

This Terraform module configures Vulnerability Assessment (VA) for Azure MySQL Flexible Server by creating the necessary Azure infrastructure.

## Overview

This module creates:
- Azure Key Vault for storing database credentials
- Azure Function App infrastructure for VA configuration
- Storage Account for Azure Function
- App Service Plan (Consumption tier)
- Managed Identity for secure access

## Prerequisites

- Azure MySQL Flexible Server already deployed
- Azure CLI authenticated
- Terraform >= 1.0
- Appropriate Azure permissions to create resources

## Usage

```hcl
module "azure_mysql_va_config" {
  source = "../../modules/azure-mysql"

  name_prefix         = "my-app"
  resource_group_name = "my-resource-group"
  location            = "canadacentral"

  # Database Connection Details
  db_host     = "my-mysql-server.mysql.database.azure.com"
  db_port     = 3306
  db_name     = "mydatabase"
  db_username = "mysqladmin"
  db_password = var.db_password

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # Guardium Server Configuration (for automatic firewall rules)
  guardium_hostname    = "guardium.example.com"  # Will be resolved to IP
  mysql_server_name    = "my-mysql-server"
  enable_public_access = true  # Enable public access for Guardium connectivity

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
| db_host | MySQL server FQDN | `string` | n/a | yes |
| db_port | MySQL server port | `number` | `3306` | no |
| db_name | Database name | `string` | n/a | yes |
| db_username | Admin username | `string` | n/a | yes |
| db_password | Admin password | `string` | n/a | yes |
| sqlguard_username | Guardium VA username | `string` | `"sqlguard"` | no |
| sqlguard_password | Guardium VA password | `string` | n/a | yes |
| guardium_hostname | Guardium server hostname (resolved to IP) | `string` | n/a | yes |
| mysql_server_name | Azure MySQL server name | `string` | n/a | yes |
| enable_public_access | Enable public access for Guardium | `bool` | `true` | no |
| vnet_name | Existing VNet name | `string` | n/a | yes |
| function_subnet_address_prefix | Function subnet CIDR | `string` | n/a | yes |

## Deployment Modes

This module supports two deployment modes for Guardium connectivity:

### Mode 1: Private Access (Production - Recommended)

**Use Case**: Production environments requiring maximum security

**Configuration**:
```hcl
module "azure_mysql_va" {
  source = "../../modules/azure-mysql"
  
  # ... other required variables ...
  
  enable_public_access = false  # Default - no public access
  # guardium_hostname and mysql_server_name not required
}
```

**Requirements**:
- MySQL server deployed with VNet integration (private access only)
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
module "azure_mysql_va" {
  source = "../../modules/azure-mysql"
  
  # ... other required variables ...
  
  # Enable public access mode
  enable_public_access = true
  guardium_hostname    = "guardium.example.com"  # Resolved to IP automatically
  mysql_server_name    = azurerm_mysql_flexible_server.mysql_server.name
}
```

**Requirements**:
- MySQL server must have `public_network_access_enabled = true`
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

2. **Firewall Rules**: Creates MySQL firewall rules:
   - **AllowGuardiumServer**: Specific Guardium IP only
   - **AllowAzureServices**: Azure Function App access

3. **Dynamic Updates**: Re-run Terraform if Guardium IP changes

| tags | Resource tags | `map(string)` | `{}` | no |

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
- Stores MySQL credentials securely
- Soft delete enabled (7 days retention)
- Access policies for Function App

### Azure Function App
- Linux-based Function App
- Python 3.9 runtime
- Consumption (Y1) plan
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

This module creates the infrastructure only. To deploy the actual function code:

1. **Using Azure CLI:**
   ```bash
   func azure functionapp publish <function-app-name>
   ```

2. **Using GitHub Actions:**
   Configure CI/CD pipeline to deploy function code

3. **Manual Deployment:**
   Package and upload function code via Azure Portal

## Function Code Requirements

The function should:
1. Retrieve credentials from Key Vault
2. Connect to MySQL server
3. Create `sqlguard` user with appropriate permissions
4. Configure database for VA scanning

Example permissions for sqlguard user:
```sql
CREATE USER 'sqlguard'@'%' IDENTIFIED BY 'password';
GRANT SELECT, SHOW VIEW ON *.* TO 'sqlguard'@'%';
GRANT PROCESS ON *.* TO 'sqlguard'@'%';
FLUSH PRIVILEGES;
```

## Cost Considerations

- **Key Vault**: ~$0.03/10,000 operations
- **Function App (Consumption)**: First 1M executions free, then $0.20/million
- **Storage Account**: ~$0.02/GB/month

**Estimated monthly cost**: < $5 for typical usage

## Limitations

- Function code must be deployed separately
- Requires Azure CLI or deployment pipeline
- Key Vault name must be globally unique (handled by name_prefix)

## Example

See the [examples/azure-mysql](../../examples/azure-mysql) directory for a complete working example.

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0