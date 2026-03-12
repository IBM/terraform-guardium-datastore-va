# Azure MySQL Flexible Server with Guardium VA - Example

This example demonstrates how to configure an Azure MySQL Flexible Server for Vulnerability Assessment (VA) and connect it to IBM Guardium Data Protection.

## Overview

This example:
1. Configures Azure MySQL Flexible Server for VA using Azure Functions
2. Creates necessary Azure infrastructure (Key Vault, Storage, Function App)
3. Registers the datasource with Guardium Data Protection
4. Configures VA scheduling and notifications

## Prerequisites

### Azure Requirements
- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Terraform >= 1.0
- Existing Azure MySQL Flexible Server (or use the deployment script in `scripts/azure-mysql-deployment/`)

### Azure CLI Authentication
You must be logged in to Azure CLI with the correct subscription:

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify current subscription
az account show --output table
```

**Common Issue**: If you see authentication errors, ensure you're logged in to the correct tenant:
```bash
az login --tenant YOUR_TENANT_ID
```

### Guardium Requirements
- IBM Guardium Data Protection instance accessible from Azure
- Guardium API credentials (client_id, client_secret)
- Guardium admin credentials

## Finding Your Azure Resources

Before configuring the variables, you need to identify your existing Azure resources. Here's how:

### 1. Find Your Resource Group

A **Resource Group** is a container that holds related Azure resources. Your MySQL server must be in a resource group.

```bash
# List all resource groups in your subscription
az group list --output table

# Example output:
# Name                Location        Status
# ------------------  --------------  ---------
# my-mysql-rg         canadacentral   Succeeded
# production-rg       eastus          Succeeded
```

Use the `Name` column value for `resource_group_name` in your tfvars.

### 2. Find Your MySQL Server

```bash
# List all MySQL Flexible Servers in your subscription (shows resource group automatically)
az mysql flexible-server list --output table

# Example output:
# Name              Resource Group   Location        Version    Storage Size(GiB)    Tier       SKU            State    HA State    Availability zone
# ----------------  ---------------  --------------  ---------  -------------------  ---------  -------------  -------  ----------  -------------------
# my-mysql-server   my-mysql-rg      Canada Central  8.0.21     20                   Burstable  Standard_B1ms  Ready    NotEnabled  2

# If you want to list servers in a specific resource group only:
# az mysql flexible-server list --resource-group <your-rg-name> --output table
```

Use the `Name` for `mysql_server_name` and construct the FQDN as `<name>.mysql.database.azure.com` for `db_host`.

### 3. Find Your Virtual Network (VNet)

A **VNet** is Azure's private network. The Function App needs a subnet in this VNet to connect to your MySQL server.

```bash
# List all VNets in your resource group
az network vnet list --resource-group <your-rg-name> --output table

# Example output:
# Name              ResourceGroup    Location        AddressPrefix
# ----------------  ---------------  --------------  ---------------
# my-mysql-vnet     my-mysql-rg      canadacentral   10.0.0.0/16
```

Use the `Name` for `vnet_name` in your tfvars.

### 4. Check Existing Subnets

```bash
# List subnets in your VNet
az network vnet subnet list --resource-group <your-rg-name> --vnet-name <your-vnet-name> --output table

# Real example (make sure to use the correct resource group name from step 1):
# az network vnet subnet list --resource-group guardium-mysql-rg-1u40jd --vnet-name guardium-mysql-vnet --output table

# Example output:
# AddressPrefix    Name                      PrivateEndpointNetworkPolicies    ProvisioningState    ResourceGroup
# ---------------  ------------------------  --------------------------------  -------------------  ------------------------
# 10.0.1.0/24      guardium-mysql-subnet     Enabled                           Succeeded            guardium-mysql-rg-1u40jd
# 10.0.2.0/24      guardium-function-subnet  Enabled                           Succeeded            guardium-mysql-rg-1u40jd
```

Choose an unused address prefix for the Function App subnet (e.g., `10.0.2.0/24`) that doesn't overlap with existing subnets.

### 5. Get MySQL Server Details

```bash
# Get full details of your MySQL server
az mysql flexible-server show \
  --name <your-server-name> \
  --resource-group <your-rg-name>

# Get just the FQDN
az mysql flexible-server show \
  --name <your-server-name> \
  --resource-group <your-rg-name> \
  --query "fullyQualifiedDomainName" -o tsv

# Example output: my-mysql-server.mysql.database.azure.com
```

### 6. Verify Your Subscription

```bash
# Show current subscription
az account show --output table

# Example output:
# Name                    SubscriptionId                        TenantId
# ----------------------  ------------------------------------  ------------------------------------
# My Azure Subscription   12345678-1234-1234-1234-123456789012  87654321-4321-4321-4321-210987654321
```

### Quick Reference Commands

```bash
# Set these variables for easier commands
RG_NAME="my-mysql-rg"
SERVER_NAME="my-mysql-server"
VNET_NAME="my-mysql-vnet"

# Get all info at once
echo "Resource Group: $RG_NAME"
echo "MySQL Server: $SERVER_NAME"
echo "MySQL FQDN: $(az mysql flexible-server show --name $SERVER_NAME --resource-group $RG_NAME --query 'fullyQualifiedDomainName' -o tsv)"
echo "VNet: $VNET_NAME"
echo "Existing Subnets:"
az network vnet subnet list --resource-group $RG_NAME --vnet-name $VNET_NAME --query "[].{Name:name, Prefix:addressPrefix}" -o table
```


## Usage

### Step 1: Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Azure Configuration
location            = "canadacentral"
resource_group_name = "my-mysql-rg"
mysql_server_name   = "my-mysql-server"

# Network Configuration
vnet_name                      = "my-vnet"
function_subnet_address_prefix = "10.0.2.0/24"

# Database Credentials
db_username = "mysqladmin"
db_password = "YourSecurePassword123!"

# Guardium Configuration
gdp_server   = "guardium.example.com"
gdp_username = "admin"
gdp_password = "YourGuardiumPassword"
client_id    = "client2"
client_secret = "your-client-secret"

# Firewall Configuration (for Guardium connectivity)
enable_public_access = true
guardium_hostname    = "guardium.example.com"

# Additional firewall rules for corporate networks
additional_firewall_rules = {
  "AllowCorporateNetwork" = {
    start_ip = "10.0.0.0"
    end_ip   = "10.255.255.255"
  }
}
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan and Apply

```bash
terraform plan
terraform apply
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │           Azure MySQL Flexible Server              │     │
│  │  • Public/Private Access                           │     │
│  │  • Firewall Rules for Guardium                     │     │
│  │  • sqlguard user with VA permissions               │     │
│  └────────────────────────────────────────────────────┘     │
│                          │                                   │
│                          │ VNet Integration                  │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐     │
│  │           Azure Function App                       │     │
│  │  • Python 3.9 Runtime                              │     │
│  │  • Managed Identity                                │     │
│  │  • Creates sqlguard user                           │     │
│  │  • Grants VA permissions                           │     │
│  └────────────────────────────────────────────────────┘     │
│                          │                                   │
│                          │ Secure Access                     │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐     │
│  │              Azure Key Vault                       │     │
│  │  • Stores database credentials                     │     │
│  │  • Managed Identity access                         │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS/TLS
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              IBM Guardium Data Protection                    │
│  • Datasource Registration                                   │
│  • Vulnerability Assessment Scheduling                       │
│  • Security Scanning & Compliance                            │
└─────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Azure CLI Session Expired

**Symptom**: Terraform operations fail with authentication errors

**Solution**:
```bash
# Re-login to Azure
az login --tenant YOUR_TENANT_ID

# Verify subscription
az account show
```

### Wrong Azure Subscription

**Symptom**: Resources not found or permission errors

**Solution**:
```bash
# List subscriptions
az account list --output table

# Set correct subscription
az account set --subscription "SUBSCRIPTION_ID"
```

### Connection Test Hangs in Guardium

**Symptom**: Guardium connection test hangs indefinitely

**Common Causes**:
1. **Corporate firewall blocking MySQL port 3306**
2. **Guardium server uses different outbound IP than expected**
3. **DNS resolution issues**

**Solutions**:

1. **Add corporate network range to firewall rules**:
   ```hcl
   additional_firewall_rules = {
     "AllowCorporateNetwork" = {
       start_ip = "10.0.0.0"
       end_ip   = "10.255.255.255"
     }
   }
   ```

2. **Find actual outbound IP and add it**:
   ```bash
   # From Guardium server, check outbound IP
   curl ifconfig.me
   
   # Add to terraform.tfvars
   additional_firewall_rules = {
     "AllowGuardiumOutbound" = {
       start_ip = "203.0.113.10"
       end_ip   = "203.0.113.10"
     }
   }
   ```

3. **Verify DNS resolution**:
   ```bash
   nslookup your-mysql-server.mysql.database.azure.com
   ```

4. **Test MySQL connectivity**:
   ```bash
   mysql -h your-server.mysql.database.azure.com \
     -u sqlguard \
     -p'YourPassword' \
     --ssl-mode=REQUIRED \
     -e "SELECT 1;"
   ```

### Function App Permission Errors

**Symptom**: Function fails with "does not have secrets get permission on key vault"

**Solution**: The module automatically creates access policies, but if you see this error:

```bash
# Get Function App's Managed Identity
PRINCIPAL_ID=$(az functionapp identity show \
  --name <function-app-name> \
  --resource-group <rg-name> \
  --query principalId -o tsv)

# Grant Key Vault permissions
az keyvault set-policy \
  --name <key-vault-name> \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

### Resource Already Exists Errors

**Symptom**: "A resource with the ID ... already exists"

**Solution**: Import existing resources:

```bash
# Import firewall rule
terraform import 'module.azure_mysql_va_config.azurerm_mysql_flexible_server_firewall_rule.guardium_access[0]' \
  '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.DBforMySQL/flexibleServers/<server>/firewallRules/AllowGuardiumServer'

# Import additional firewall rules
terraform import 'module.azure_mysql_va_config.azurerm_mysql_flexible_server_firewall_rule.additional_rules["AllowCorporateNetwork"]' \
  '/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.DBforMySQL/flexibleServers/<server>/firewallRules/AllowCorporateNetwork'
```

### Verify Function Execution

Check if the Azure Function successfully created the sqlguard user:

```bash
# Get function key
FUNCTION_KEY=$(az functionapp function keys list \
  --resource-group <rg-name> \
  --name <function-app-name> \
  --function-name MySQLVAConfig \
  --query "default" -o tsv)

# Invoke function
curl -X POST \
  "https://<function-app-name>.azurewebsites.net/api/MySQLVAConfig?code=$FUNCTION_KEY" \
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
    {"operation": "grant_select_mysql_user", "status": "success"},
    {"operation": "grant_select_mysql_db", "status": "success"},
    {"operation": "grant_show_databases", "status": "success"},
    {"operation": "flush_privileges", "status": "success"}
  ]
}
```

### Check Function Logs

View real-time logs from the Azure Function:

```bash
az webapp log tail \
  --resource-group <rg-name> \
  --name <function-app-name>
```

### Verify Firewall Rules

List current firewall rules:

```bash
az mysql flexible-server firewall-rule list \
  --resource-group <rg-name> \
  --name <server-name> \
  --output table
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will remove the VA configuration but not the MySQL server itself (if it was created separately).

## Security Best Practices

1. **Use Private Link in Production**: For production environments, use Azure Private Link instead of public access
2. **Restrict Firewall Rules**: Only allow specific IP ranges, never use 0.0.0.0/0
3. **Rotate Credentials**: Regularly rotate database and Guardium credentials
4. **Enable Audit Logging**: Enable MySQL audit logs for compliance
5. **Use Key Vault**: Store all sensitive credentials in Azure Key Vault
6. **Monitor Function Logs**: Regularly review Azure Function execution logs

## Support

For issues or questions:
- Check the [module README](../../modules/azure-mysql/README.md) for detailed documentation
- Review the troubleshooting section above
- Check Azure Function logs for execution errors
- Verify Guardium connectivity and credentials