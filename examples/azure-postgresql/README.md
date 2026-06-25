# Azure PostgreSQL Flexible Server VA Configuration Example

This example demonstrates how to configure Vulnerability Assessment (VA) for Azure PostgreSQL Flexible Server using Terraform.

## Overview

This example creates:
1. Azure Key Vault for storing PostgreSQL credentials
2. Azure Function App for VA user configuration
3. Storage Account and App Service Plan
4. VNet integration for secure connectivity
5. Firewall rules for Guardium access (optional)
6. Guardium datasource configuration template

## Prerequisites

### Required
- Azure PostgreSQL Flexible Server already deployed (see Phase 1)
- Azure CLI installed and authenticated (`az login`)
- Terraform >= 1.0
- Appropriate Azure permissions (Contributor or Owner on resource group)

### Phase 1 Integration
This example is designed to work with the Phase 1 infrastructure deployment from:
```
scripts/azure-postgresql-deployment/
```

You'll need the following outputs from Phase 1:
- `resource_group_name`
- `postgresql_server_name`
- `db_host` (FQDN)
- `vnet_name`
- `db_name`
- `db_username`
- `db_password`

## Usage

### Step 1: Copy and Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### Step 2: Update Variables with Phase 1 Outputs

```hcl
# From Phase 1 deployment
resource_group_name    = "guardium-postgresql-rg"
postgresql_server_name = "guardium-postgresql-server"
db_host                = "guardium-postgresql-server.postgres.database.azure.com"
vnet_name              = "guardium-postgresql-vnet"
db_name                = "testdb"
db_username            = "pgadmin"
db_password            = "<from-phase-1>"

# New for VA
name_prefix                    = "guardium-pg-va"
function_subnet_address_prefix = "10.0.2.0/24"  # Must not overlap with Phase 1 subnets
sqlguard_password              = "SecurePassword123!"

# Guardium connection
gdp_host     = "guardium.example.com"
gdp_username = "admin"
gdp_password = "<your-guardium-password>" # pragma: allowlist secret
```

### Step 3: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 4: Verify Function Deployment

Wait 5-10 minutes for the Azure Function to be fully deployed, then invoke it:

```bash
# Get function key
FUNCTION_KEY=$(az functionapp function keys list \
  --resource-group <resource-group-name> \
  --name <function-app-name> \
  --function-name PostgreSQLVAConfig \
  --query "default" -o tsv)

# Invoke function to create sqlguard user
curl -X POST \
  "https://<function-app-name>.azurewebsites.net/api/PostgreSQLVAConfig?code=$FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected response:
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

### Step 5: Configure Guardium

1. Log in to Guardium UI
2. Navigate to Data Sources
3. Add new datasource using the configuration from `terraform output guardium_datasource_config`
4. Test connection
5. Schedule VA scan

## Deployment Modes

### Private Access (Production - Recommended)

```hcl
enable_public_access = false
```

- PostgreSQL server must have VNet integration
- Guardium connects via Azure Private Link or VPN/ExpressRoute
- No public firewall rules created
- Maximum security

### Public Access with Firewall (Testing/Demo)

```hcl
enable_public_access = true
guardium_hostname    = "guardium.example.com"

additional_firewall_rules = {
  "AllowCorporateNetwork" = {
    start_ip = "10.0.0.0"
    end_ip   = "10.255.255.255"
  }
}
```

- Creates firewall rules for Guardium IP
- Suitable for testing and demos
- Less secure than Private Link

## Outputs

| Output | Description |
|--------|-------------|
| `function_app_name` | Name of the Azure Function App |
| `key_vault_name` | Name of the Key Vault storing credentials |
| `sqlguard_username` | Username for Guardium VA user |
| `guardium_resolved_ip` | Resolved IP of Guardium server |
| `guardium_datasource_config` | Datasource configuration for Guardium |

## Troubleshooting

### Connection Test Hangs

**Problem**: Guardium connection test hangs indefinitely

**Solutions**:
1. Check if corporate firewall blocks port 5432
2. Verify Guardium's outbound IP matches firewall rules
3. Add additional firewall rules for NAT gateway IP
4. Temporarily allow all IPs to diagnose (testing only)

See module README for detailed troubleshooting steps.

### Function Permission Errors

**Problem**: Function fails with Key Vault permission error

**Solution**:
```bash
# Verify managed identity
az functionapp identity show \
  --name <function-app-name> \
  --resource-group <resource-group-name>

# Grant permissions manually if needed
az keyvault set-policy \
  --name <key-vault-name> \
  --object-id <function-principal-id> \
  --secret-permissions get list
```

### Subnet Overlap

**Problem**: Subnet creation fails with "overlapping address space"

**Solution**: Choose a different subnet range that doesn't overlap with Phase 1:
```hcl
function_subnet_address_prefix = "10.0.3.0/24"  # Try different range
```

## Testing Connection

Test PostgreSQL connectivity from command line:

```bash
# Test with sqlguard user
psql -h <server>.postgres.database.azure.com \
  -U sqlguard \
  -d <database> \
  -c "SELECT 1 as test;" \
  sslmode=require

# Test with timeout
timeout 10 psql -h <server>.postgres.database.azure.com \
  -U sqlguard \
  -d <database> \
  -c "SELECT 1 as test;" \
  sslmode=require
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will delete:
- Azure Function App
- Key Vault (with 7-day soft delete)
- Storage Account
- Function subnet
- Firewall rules

The PostgreSQL server and Phase 1 infrastructure will remain intact.

## Integration with Phase 1

This example is designed to integrate seamlessly with Phase 1 infrastructure:

```
Phase 1 (scripts/azure-postgresql-deployment/)
├── Resource Group
├── VNet (10.0.0.0/16)
├── PostgreSQL Subnet (10.0.1.0/24)
├── PostgreSQL Flexible Server
└── Database

Phase 2 (this example)
├── Function Subnet (10.0.2.0/24)  ← New subnet in existing VNet
├── Azure Function App
├── Key Vault
├── Storage Account
└── Firewall Rules (optional)
```

## Cost Estimate

Monthly costs (approximate):
- Azure Function (EP1): ~$150
- Key Vault: ~$0.03/10k operations
- Storage Account: ~$0.02/GB
- **Total**: ~$150-160/month

## Security Best Practices

1. **Use Private Access**: Set `enable_public_access = false` in production
2. **Rotate Passwords**: Regularly rotate `sqlguard_password`
3. **Restrict Firewall**: Use minimal IP ranges in `additional_firewall_rules`
4. **Monitor Access**: Enable Azure Monitor for Function App
5. **Use Key Vault**: Store all secrets in Azure Key Vault

## Next Steps

After successful deployment:

1. **Configure Guardium**: Add datasource in Guardium UI
2. **Test Connection**: Verify connectivity from Guardium
3. **Schedule VA Scan**: Set up regular vulnerability assessments
4. **Monitor Results**: Review VA findings in Guardium dashboard
5. **Remediate Issues**: Address identified vulnerabilities

## Support

For issues or questions:
- Check module README: `../../modules/azure-postgresql/README.md`
- Review troubleshooting section above
- Check Azure Function logs in Azure Portal

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
