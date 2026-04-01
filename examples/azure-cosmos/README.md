# Azure Cosmos DB with Guardium VA - Example

This example demonstrates how to configure an Azure Cosmos DB account for Vulnerability Assessment (VA) and connect it to IBM Guardium Data Protection.

## Overview

This example:
1. Configures Azure Cosmos DB for VA using Azure Functions
2. Creates necessary Azure infrastructure (Key Vault, Storage, Function App)
3. Registers the datasource with Guardium Data Protection
4. Configures VA scheduling and notifications

## Prerequisites

### Azure Requirements
- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Terraform >= 1.0
- Existing Azure Cosmos DB account (or use the deployment script in `scripts/azure-cosmos-deployment/`)

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

A **Resource Group** is a container that holds related Azure resources. Your Cosmos DB account must be in a resource group.

```bash
# List all resource groups in your subscription
az group list --output table

# Example output:
# Name                      Location    Status
# ------------------------  ----------  ---------
# gdcosmos-cosmos-rg-g0qad6 eastus      Succeeded
# production-rg             eastus      Succeeded
```

Use the `Name` column value for `resource_group_name` in your tfvars.

### 2. Find Your Cosmos DB Account

```bash
# List all Cosmos DB accounts in your subscription
az cosmosdb list --output table

# Example output:
# Name                    Resource Group            Location    Kind
# ----------------------  ------------------------  ----------  ---------------
# gdcosmos-cosmos-g0qad6  gdcosmos-cosmos-rg-g0qad6 East US     GlobalDocumentDB

# If you want to list accounts in a specific resource group only:
# az cosmosdb list --resource-group <your-rg-name> --output table
```

Use the `Name` for `cosmos_account_name`.

### 3. Get Cosmos DB Endpoint

```bash
# Get the document endpoint
az cosmosdb show \
  --name <your-account-name> \
  --resource-group <your-rg-name> \
  --query "documentEndpoint" -o tsv

# Example output: https://gdcosmos-cosmos-g0qad6.documents.azure.com:443/
```

Use this for `cosmos_endpoint` and extract the hostname (without https:// and :443/) for `cosmos_endpoint_hostname`.

### 4. Get Cosmos DB Primary Key

```bash
# Get the primary master key
az cosmosdb keys list \
  --name <your-account-name> \
  --resource-group <your-rg-name> \
  --query "primaryMasterKey" -o tsv

# This is a sensitive value - keep it secure!
```

Use this for `cosmos_primary_key`.

### 5. Find Your Virtual Network (VNet)

A **VNet** is Azure's private network. The Function App needs a subnet in this VNet to connect to your Cosmos DB.

```bash
# List all VNets in your resource group
az network vnet list --resource-group <your-rg-name> --output table

# Example output:
# Name                  ResourceGroup             Location    AddressPrefix
# --------------------  ------------------------  ----------  ---------------
# gdcosmos-cosmos-vnet  gdcosmos-cosmos-rg-g0qad6 eastus      10.0.0.0/16
```

Use the `Name` for `vnet_name` in your tfvars.

### 6. Check Existing Subnets

```bash
# List subnets in your VNet
az network vnet subnet list \
  --resource-group <your-rg-name> \
  --vnet-name <your-vnet-name> \
  --output table

# Example output:
# AddressPrefix    Name                      ProvisioningState
# ---------------  ------------------------  -------------------
# 10.0.1.0/24      gdcosmos-cosmos-subnet    Succeeded
```

Choose an unused address prefix for the Function App subnet (e.g., `10.0.2.0/24`) that doesn't overlap with existing subnets.

### 7. List Databases and Containers

```bash
# List SQL databases
az cosmosdb sql database list \
  --account-name <your-account-name> \
  --resource-group <your-rg-name> \
  --output table

# List containers in a database
az cosmosdb sql container list \
  --account-name <your-account-name> \
  --resource-group <your-rg-name> \
  --database-name <your-database-name> \
  --output table
```

### Quick Reference Commands

```bash
# Set these variables for easier commands
RG_NAME="gdcosmos-cosmos-rg-g0qad6"
ACCOUNT_NAME="gdcosmos-cosmos-g0qad6"
VNET_NAME="gdcosmos-cosmos-vnet"

# Get all info at once
echo "Resource Group: $RG_NAME"
echo "Cosmos DB Account: $ACCOUNT_NAME"
echo "Cosmos DB Endpoint: $(az cosmosdb show --name $ACCOUNT_NAME --resource-group $RG_NAME --query 'documentEndpoint' -o tsv)"
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
location            = "eastus"
resource_group_name = "gdcosmos-cosmos-rg-g0qad6"
cosmos_account_name = "gdcosmos-cosmos-g0qad6"

# Network Configuration
vnet_name                      = "gdcosmos-cosmos-vnet"
function_subnet_address_prefix = "10.0.2.0/24"

# Cosmos DB Details
cosmos_endpoint          = "https://gdcosmos-cosmos-g0qad6.documents.azure.com:443/"
cosmos_endpoint_hostname = "gdcosmos-cosmos-g0qad6.documents.azure.com"
cosmos_primary_key       = "your-primary-key-here"
database_name            = "testdb"
container_name           = "testcontainer"

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "YourGuardiumPassword"
client_id     = "client2"
client_secret = "your-client-secret"

# Firewall Configuration (for Guardium connectivity)
enable_public_access = true
guardium_ip_address  = "203.0.113.10/32"
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
│  │           Azure Cosmos DB Account                  │     │
│  │  • SQL API or MongoDB API                          │     │
│  │  • Public/Private Access                           │     │
│  │  • Firewall Rules for Guardium                     │     │
│  │  • Primary Key Authentication                      │     │
│  └────────────────────────────────────────────────────┘     │
│                          │                                   │
│                          │ VNet Integration                  │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐     │
│  │      Azure Function App (EP1 Service Plan)         │     │
│  │  • Python 3.9 Runtime                              │     │
│  │  • Managed Identity (System-Assigned)              │     │
│  │  • VA Configuration Automation                     │     │
│  │  • 1 vCPU, 3.5 GB RAM (Premium Tier)               │     │
│  │  • Always-On capability                            │     │
│  │  • VNet Integration for secure connectivity        │     │
│  └────────────────────────────────────────────────────┘     │
│                          │                                   │
│                          │ Secure Access                     │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────┐     │
│  │              Azure Key Vault                       │     │
│  │  • Stores Cosmos DB credentials                    │     │
│  │  • Managed Identity access                         │     │
│  │  • Access policies for Function App                │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │           Storage Account                          │     │
│  │  • Function App state and logs                     │     │
│  │  • Deployment packages                             │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS/TLS (Port 443)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              IBM Guardium Data Protection                    │
│  • Datasource Registration (Type: Azure CosmosDB)           │
│  • Vulnerability Assessment Scheduling                       │
│  • Security Scanning & Compliance                            │
└─────────────────────────────────────────────────────────────┘
```

## Azure Function App (EP1 Service Plan) Explained

### What is the Azure Function App?

The **Azure Function App** is a serverless compute service that runs Python code to automate VA configuration tasks for Azure Cosmos DB. It acts as a bridge between Guardium and Cosmos DB for vulnerability assessment operations.

### What is EP1 Service Plan?

**EP1 (Elastic Premium 1)** is a premium-tier App Service Plan that provides:

| Feature | EP1 Plan | Consumption Plan (Alternative) |
|---------|----------|-------------------------------|
| **vCPU** | 1 dedicated vCPU | Shared, variable |
| **Memory** | 3.5 GB RAM | 1.5 GB RAM |
| **Cold Start** | Minimal (pre-warmed) | 5-10 seconds |
| **VNet Integration** | ✅ Yes (included) | ❌ No (requires Premium) |
| **Always-On** | ✅ Yes | ❌ No |
| **Cost** | ~$150/month | Pay-per-execution |
| **Best For** | Production workloads | Development/testing |

### Why EP1 is Required for This Solution

1. **VNet Integration** ✅
   - Function App needs to connect to Cosmos DB via private network
   - Subnet: `gdcosmos2-function-subnet` (10.0.2.0/24)
   - Enables secure communication without public internet exposure

2. **Reliable Performance**
   - No cold starts during VA assessments
   - Consistent response times for Guardium requests
   - Better for scheduled vulnerability scans

3. **Key Vault Access**
   - Managed Identity requires stable compute environment
   - Secure credential retrieval from Key Vault
   - No hardcoded secrets in function code

### What the Function App Does

```
┌─────────────────────────────────────────────────────────────┐
│  Guardium Triggers VA Assessment                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Azure Function App Receives Request                        │
│  1. Authenticates using Managed Identity                    │
│  2. Retrieves Cosmos DB credentials from Key Vault          │
│  3. Connects to Cosmos DB via VNet (secure)                 │
│  4. Executes VA configuration commands                      │
│  5. Collects database metadata and security settings        │
│  6. Returns results to Guardium                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Guardium Processes VA Results                              │
│  • Identifies vulnerabilities                               │
│  • Generates compliance reports                             │
│  • Sends notifications (if configured)                      │
└─────────────────────────────────────────────────────────────┘
```

### Function App Components Deployed

1. **Service Plan**: `gdcosmos2-cosmos-va-plan`
   - SKU: EP1 (Elastic Premium 1)
   - OS: Linux
   - Location: East US

2. **Function App**: `gdcosmos2-cosmos-va-func`
   - Runtime: Python 3.9
   - Managed Identity: System-assigned
   - VNet Integration: Enabled
   - App Settings:
     - `FUNCTIONS_WORKER_RUNTIME=python`
     - `KEY_VAULT_NAME=gdcosmos2-cosmos-kv-8sd3`
     - `SECRET_NAME=gdcosmos2-azure-cosmos-va-credentials`
     - `AZURE_SUBSCRIPTION_ID=85de16ef-7645-417d-acff-f5bee9c2e45e`

3. **Storage Account**: `gdcosmos2cosmosva4olt`
   - Purpose: Function App state, logs, deployment packages
   - Type: Standard LRS

4. **Key Vault**: `gdcosmos2-cosmos-kv-8sd3`
   - Stores: Cosmos DB primary key
   - Access: Function App Managed Identity
   - Secret: `gdcosmos2-azure-cosmos-va-credentials`

5. **VNet Integration**
   - Subnet: `gdcosmos2-function-subnet`
   - Address Space: 10.0.2.0/24
   - Delegation: Microsoft.Web/serverFarms

### Function Code Structure

The deployed function (`function.zip`) contains:

```
function.zip
├── __init__.py          # Main function handler
├── requirements.txt     # Python dependencies
├── host.json           # Function App configuration
└── function.json       # Function binding configuration
```

**Key Operations**:
- Authenticate with Azure using Managed Identity
- Retrieve Cosmos DB credentials from Key Vault
- Connect to Cosmos DB using Azure SDK
- Execute VA configuration queries
- Return structured results to Guardium

### Monitoring the Function App

```bash
# View real-time logs
az webapp log tail \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --name gdcosmos2-cosmos-va-func

# Check function execution history
az functionapp function show \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --name gdcosmos2-cosmos-va-func \
  --function-name CosmosVAConfig

# View metrics
az monitor metrics list \
  --resource /subscriptions/85de16ef-7645-417d-acff-f5bee9c2e45e/resourceGroups/gdcosmos2-cosmos-rg-cq8kca/providers/Microsoft.Web/sites/gdcosmos2-cosmos-va-func \
  --metric "FunctionExecutionCount"
```

### Cost Considerations

**EP1 Plan Pricing** (approximate):
- Base cost: ~$150/month (24/7 availability)
- Execution cost: Minimal (included in plan)
- Storage: ~$0.05/GB/month
- Key Vault: ~$0.03/10,000 operations

**Total Monthly Cost**: ~$155-160/month

**Alternative**: Consumption Plan (~$5-10/month) but lacks VNet integration required for secure connectivity.

## Guardium Datasource Configuration

### Automated Registration (via Terraform)

The Terraform configuration automatically registers the datasource with Guardium using basic authentication. However, **Azure-specific authentication parameters cannot be set via REST API** and must be configured manually through the Guardium UI.

### Manual Azure Authentication Configuration (REQUIRED)

After running `terraform apply`, you **MUST** complete the Azure authentication configuration in the Guardium UI:

#### Step-by-Step Instructions:

1. **Login to Guardium UI**
   - Navigate to: `https://your-guardium-server:8443`
   - Login with admin credentials

2. **Navigate to Datasources**
   - Click on **"Datasource Definitions"** in the left menu
   - Click on the **"Datasources"** tab
   - Find your datasource: `azure-cosmos-va-test` (or your configured name)
   - Status will show **"Not tested"** (red icon)

3. **Edit the Datasource**
   - Click the **pencil icon** (Edit) next to your datasource
   - The "Update datasource" dialog will open

4. **Configure Connection Tab** (Already populated by Terraform)
   - ✅ Application type: `Security Assessment`
   - ✅ Name: `azure-cosmos-va-test`
   - ✅ Database type: `Azure CosmosDB`
   - ✅ Description: `Azure Cosmos DB deployed via Terraform with VA`
   - ✅ Use SSL: Checked
   - ✅ Import server ssl certificate: Checked (if needed)

5. **Configure Authentication Section** (MANUAL - CRITICAL STEP)
   
   Scroll down to the **"Authentication"** section and fill in these fields:

   ```
   Location:
   ├─ Client ID: 00000000-0000-0000-0000-000000000000
   ├─ Client Secret: your-azure-client-secret-here
   ├─ Database Account Name: your-cosmos-account-name
   └─ Connection property: (leave as default or add custom properties)
   ```

   **Important Notes:**
   - **Client ID**: Azure Service Principal Application (Client) ID
   - **Client Secret**: Azure Service Principal Secret Value
   - **Database Account Name**: Your Cosmos DB account name (same as hostname prefix)
   - These values are from your `terraform.tfvars` file

6. **Click "Advanced" Tab** (Optional but Recommended)
   
   Add additional Azure authentication parameters:
   
   ```
   Subscription ID: 85de16ef-7645-417d-acff-f5bee9c2e45e
   Tenant ID: 32bfacf3-8eb1-498d-b7d9-6f567cf065cd
   Resource Group: gdcosmos2-cosmos-rg-cq8kca
   ```

7. **Test Connection**
   - Click the **"Test connection"** button at the bottom
   - Wait for the test to complete (may take 10-30 seconds)
   - You should see: ✅ **"Connection successful from host 'rr-cm-23'"** message
   - The status indicator will show a green checkmark ✅
   - If it fails, see the [Troubleshooting](#troubleshooting) section below

8. **Save Configuration**
   - Click **"Save"** button
   - The datasource status should change to ✅ **"Tested"** (green checkmark in the datasource list)
   - The datasource is now ready for vulnerability assessment

### Successful Connection Example

When properly configured, you will see:

```
✅ Connection successful

Connection successful from host 'rr-cm-23'.
```

**Screenshot Reference**: The datasource list will show:
- **Status**: Green checkmark ✅ (instead of red "Not tested")
- **Name**: azure-cosmos-va-test
- **Type**: Azure CosmosDB

**What This Means**:
- ✅ Azure authentication is working (Service Principal credentials valid)
- ✅ Firewall rules allow Guardium server access
- ✅ Service Principal has required permissions
- ✅ Network connectivity is established
- ✅ Cosmos DB is accessible and responding

### Why Manual Configuration is Required

**Technical Limitation**: Guardium's REST API (`/restAPI/datasource`) does not support Azure-specific authentication parameters:
- `clientId`
- `clientSecret`
- `subscriptionId`
- `tenantId`
- `resourceGroup`

When these parameters are included in the REST API request, Guardium returns:
```
Error 27: "One or more of the parameters are not recognized"
```

**Workaround**: Two-step process
1. ✅ Terraform registers basic datasource (name, host, port, type)
2. ⚠️ Manual UI configuration adds Azure authentication

### Datasource Properties After Configuration

| Property | Value | Source |
|----------|-------|--------|
| **Name** | azure-cosmos-va-test | Terraform (configurable) |
| **Type** | Azure CosmosDB | Terraform (fixed) |
| **Host** | gdcosmos2-cosmos-cq8kca.documents.azure.com | Terraform |
| **Port** | 443 | Terraform (HTTPS) |
| **User** | gdcosmos2-cosmos-cq8kca | Terraform (account name) |
| **Password** | XSQ3hsqe... | Terraform (primary key) |
| **Application** | Security Assessment | Terraform |
| **Severity** | MED | Terraform |
| **Client ID** | f9e81657-... | **Manual UI** ⚠️ |
| **Client Secret** | 1nA8Q~fE... | **Manual UI** ⚠️ |
| **Subscription ID** | 85de16ef-... | **Manual UI** ⚠️ |
| **Tenant ID** | 32bfacf3-... | **Manual UI** ⚠️ |
| **Resource Group** | gdcosmos2-cosmos-rg-cq8kca | **Manual UI** ⚠️ |
| **Database Account** | gdcosmos2-cosmos-cq8kca | **Manual UI** ⚠️ |

### Finding Your Azure Authentication Values

All values are in your `terraform.tfvars` file:

```bash
# View your configuration
cat terraform.tfvars | grep -E "azure_client_id|azure_client_secret|azure_subscription_id|azure_tenant_id|resource_group_name|cosmos_account_name"
```

Output example:
```
azure_subscription_id = "00000000-0000-0000-0000-000000000000"
azure_tenant_id       = "00000000-0000-0000-0000-000000000000"
azure_client_id       = "00000000-0000-0000-0000-000000000000"
azure_client_secret   = "your-azure-client-secret-here"
resource_group_name   = "your-resource-group-name"
cosmos_account_name   = "your-cosmos-account-name"
```

## Troubleshooting

### Common Connection Errors and Solutions

Based on real deployment experience, here are the most common errors and their solutions:

---

### Error 1: NullPointerException - Azure Resource Manager Not Initialized

**Full Error Message**:
```
Connection unsuccessful
Could not connect to: 'https://gdcosmos2-cosmos-cq8kca.documents.azure.com:443'
for user: 'azure-cosmos-va-test_AZURE COSMOSDB(Security Assessment)'.
NullPointerException: Cannot invoke "com.azure.resourcemanager.AzureResourceManager.cosmosDBAccounts()"
because "<local1>" is null
```

**Root Cause**: Missing Azure authentication parameters (Subscription ID, Tenant ID, Resource Group)

**Solution**: Add these parameters in the **Connection property** field:

```
subscriptionId=85de16ef-7645-417d-acff-f5bee9c2e45e;tenantId=32bfacf3-8eb1-498d-b7d9-6f567cf065cd;resourceGroup=gdcosmos2-cosmos-rg-cq8kca
```

**Step-by-Step Fix**:
1. In Guardium UI, edit the datasource
2. Go to **Connection** tab
3. Scroll to **Connection property** field
4. Replace the example text with your actual values:
   ```
   subscriptionId=YOUR_SUBSCRIPTION_ID;tenantId=YOUR_TENANT_ID;resourceGroup=YOUR_RESOURCE_GROUP
   ```
5. Click **Save**
6. Click **Test connection**

**How to Find These Values**:
```bash
# Get all values at once
cat terraform.tfvars | grep -E "azure_subscription_id|azure_tenant_id|resource_group_name"

# Output:
# azure_subscription_id = "85de16ef-7645-417d-acff-f5bee9c2e45e"
# azure_tenant_id       = "32bfacf3-8eb1-498d-b7d9-6f567cf065cd"
# resource_group_name   = "gdcosmos2-cosmos-rg-cq8kca"
```

---

### Error 2: Connection Failed from Host - Firewall Blocking

**Error Message**:
```
Connection unsuccessful
Connection failed from host 'rr-cm-23' with error:
```

**Root Cause**: Guardium server IP is not in Cosmos DB firewall rules

**Solution**: Add the correct Guardium server IP to Cosmos DB firewall

**Step 1: Find Guardium Server IP**:
```bash
# Resolve Guardium hostname to IP
nslookup rr-cm-23.dev.fyre.ibm.com

# Output:
# Name:    rr-cm-23.dev.fyre.ibm.com
# Address: 9.46.196.79
```

**Step 2: Check Current Firewall Rules**:
```bash
az cosmosdb show \
  --name gdcosmos2-cosmos-cq8kca \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --query "ipRules" -o table

# Output:
# IpAddressOrRange
# ------------------
# 9.30.251.23/32
```

**Step 3: Add Guardium IP to Firewall**:
```bash
# Add the correct IP (9.46.196.79)
az cosmosdb update \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --name gdcosmos2-cosmos-cq8kca \
  --ip-range-filter "9.30.251.23,9.46.196.79"
```

**Step 4: Verify Firewall Rules Updated**:
```bash
az cosmosdb show \
  --name gdcosmos2-cosmos-cq8kca \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --query "ipRules" -o table

# Should show both IPs:
# IpAddressOrRange
# ------------------
# 9.30.251.23
# 9.46.196.79
```

**Update terraform.tfvars**:
```hcl
guardium_ip_address = "9.46.196.79/32"  # Use the correct resolved IP
```

---

### Error 3: Authorization Failed - Missing Service Principal Permissions

**Error Message** (may not be explicit, but connection fails after firewall is fixed):
```
Connection unsuccessful
Authorization failed
```

**Root Cause**: Service Principal has no permissions to access Cosmos DB

**Solution**: Assign "DocumentDB Account Contributor" role to Service Principal

**Step 1: Check Current Permissions**:
```bash
# Check if Service Principal has any roles
az role assignment list \
  --assignee f9e81657-ef97-4cfa-8836-ce55b12791c3 \
  --scope /subscriptions/85de16ef-7645-417d-acff-f5bee9c2e45e/resourceGroups/gdcosmos2-cosmos-rg-cq8kca \
  --output table

# If empty, no permissions are assigned!
```

**Step 2: Assign Required Role**:
```bash
az role assignment create \
  --assignee f9e81657-ef97-4cfa-8836-ce55b12791c3 \
  --role "DocumentDB Account Contributor" \
  --scope /subscriptions/85de16ef-7645-417d-acff-f5bee9c2e45e/resourceGroups/gdcosmos2-cosmos-rg-cq8kca/providers/Microsoft.DocumentDB/databaseAccounts/gdcosmos2-cosmos-cq8kca
```

**Step 3: Verify Role Assignment**:
```bash
az role assignment list \
  --assignee f9e81657-ef97-4cfa-8836-ce55b12791c3 \
  --scope /subscriptions/85de16ef-7645-417d-acff-f5bee9c2e45e/resourceGroups/gdcosmos2-cosmos-rg-cq8kca \
  --output table

# Should show:
# Principal                             Role                            Scope
# ------------------------------------  ------------------------------  --------
# f9e81657-ef97-4cfa-8836-ce55b12791c3  DocumentDB Account Contributor  /subscriptions/.../gdcosmos2-cosmos-cq8kca
```

**Why This Role is Needed**:
- Read Cosmos DB account properties
- Access database metadata
- Perform vulnerability assessment operations
- Query database configuration

---

### Complete Connection Test Checklist

Before testing the connection in Guardium UI, verify all these are configured:

#### ✅ Connection Tab:
- [ ] **Client ID**: `00000000-0000-0000-0000-000000000000`
- [ ] **Client Secret**: `your-azure-client-secret-here`
- [ ] **Database Account Name**: `your-cosmos-account-name`
- [ ] **Connection property**: `subscriptionId=00000000-0000-0000-0000-000000000000;tenantId=00000000-0000-0000-0000-000000000000;resourceGroup=your-resource-group-name`

#### ✅ Azure Firewall:
```bash
# Verify Guardium IP is in firewall
az cosmosdb show \
  --name gdcosmos2-cosmos-cq8kca \
  --resource-group gdcosmos2-cosmos-rg-cq8kca \
  --query "ipRules[].ipAddressOrRange" -o tsv

# Should include: 9.46.196.79
```

#### ✅ Service Principal Permissions:
```bash
# Verify role assignment exists
az role assignment list \
  --assignee f9e81657-ef97-4cfa-8836-ce55b12791c3 \
  --role "DocumentDB Account Contributor" \
  --output table

# Should show at least one role assignment
```

---

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

**Symptom**: Guardium connection test hangs indefinitely (no error message)

**Common Causes**:
1. **Firewall blocking HTTPS port 443**
2. **Guardium server IP not in Cosmos DB firewall rules**
3. **DNS resolution issues**

**Solutions**:

1. **Verify DNS resolution**:
   ```bash
   nslookup gdcosmos2-cosmos-cq8kca.documents.azure.com
   ```

2. **Test Cosmos DB connectivity from Guardium server**:
   ```bash
   # Using curl to test HTTPS connectivity
   curl -v https://gdcosmos2-cosmos-cq8kca.documents.azure.com:443/
   ```

3. **Check network connectivity**:
   ```bash
   # Test port 443 connectivity
   telnet gdcosmos2-cosmos-cq8kca.documents.azure.com 443
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

### Verify Function Execution

Check if the Azure Function successfully configured VA:

```bash
# Get function key
FUNCTION_KEY=$(az functionapp function keys list \
  --resource-group <rg-name> \
  --name <function-app-name> \
  --function-name CosmosVAConfig \
  --query "default" -o tsv)

# Invoke function
curl -X POST \
  "https://<function-app-name>.azurewebsites.net/api/CosmosVAConfig?code=$FUNCTION_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Check Function Logs

View real-time logs from the Azure Function:

```bash
az webapp log tail \
  --resource-group <rg-name> \
  --name <function-app-name>
```

### Verify Firewall Rules

List current Cosmos DB firewall rules:

```bash
az cosmosdb show \
  --name <account-name> \
  --resource-group <rg-name> \
  --query "ipRules" -o table
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will remove the VA configuration but not the Cosmos DB account itself (if it was created separately).

**Important**: Azure Cosmos DB and Key Vault have soft-delete retention (7 days by default). If you need to completely remove them:

```bash
# Delete resource group with no-wait to avoid hanging
az group delete --name <rg-name> --yes --no-wait
```

## Security Best Practices

1. **Use Private Link in Production**: For production environments, use Azure Private Link instead of public access
2. **Restrict Firewall Rules**: Only allow specific IP ranges, never use 0.0.0.0/0
3. **Rotate Keys**: Regularly rotate Cosmos DB primary keys and Guardium credentials
4. **Enable Audit Logging**: Enable Cosmos DB diagnostic logs for compliance
5. **Use Key Vault**: Store all sensitive credentials in Azure Key Vault
6. **Monitor Function Logs**: Regularly review Azure Function execution logs
7. **Use Managed Identity**: Leverage Azure Managed Identity for service-to-service authentication

## Cosmos DB Specific Considerations

### API Types
- **SQL API (GlobalDocumentDB)**: Default, supports SQL-like queries
- **MongoDB API**: Compatible with MongoDB drivers and tools

### Authentication
- **Primary/Secondary Keys**: Master keys with full access (used in this example)
- **Resource Tokens**: Fine-grained access control (future enhancement)

### Connectivity
- **Port**: Always 443 (HTTPS)
- **SSL**: Always enabled for Cosmos DB
- **Endpoint Format**: `https://<account-name>.documents.azure.com:443/`

## Support

For issues or questions:
- Check the [module README](../../modules/azure-cosmos/README.md) for detailed documentation
- Review the troubleshooting section above
- Check Azure Function logs for execution errors
- Verify Guardium connectivity and credentials
- Ensure Cosmos DB firewall rules include Guardium IP

## Related Documentation

- [Azure Cosmos DB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)