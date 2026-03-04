# Azure MySQL with Vulnerability Assessment Example

This example demonstrates how to configure Vulnerability Assessment (VA) for an Azure MySQL Flexible Server using Terraform.

## Overview

This example:
1. Configures VA on an existing Azure MySQL Flexible Server by creating Azure Function infrastructure
2. Registers the Azure MySQL server as a datasource in Guardium Data Protection (GDP)
3. Configures vulnerability assessment schedules and notifications

## Prerequisites

- An existing Azure MySQL Flexible Server (use the deployment script in `scripts/azure-mysql-deployment`)
- Azure resource group where the MySQL server is deployed
- Azure CLI authenticated
- A Guardium Data Protection instance
- Guardium OAuth client credentials (see [Preparing Guardium](../../docs/preparing-guardium.md))

## Usage

### 1. Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

Fill in your values:

```hcl
# Azure Configuration
location            = "canadacentral"
resource_group_name = "guardium-mysql-rg-1u40jd"  # From deployment script

# MySQL Server Details
db_host     = "guardium-mysql-1u40jd.mysql.database.azure.com"
db_username = "mysqladmin"
db_password = "YourSecurePassword!"

# VA User Credentials
sqlguard_username = "sqlguard"
sqlguard_password = "YourSqlGuardPassword!"

# Guardium Server Details
gdp_server    = "your-guardium-server.example.com"
gdp_username  = "admin"
gdp_password  = "YourGuardiumPassword!"
client_secret = "your-oauth-client-secret"

# Notification Settings
notification_emails = ["security-team@example.com"]
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Planned Changes

```bash
terraform plan
```

### 5. Apply the Configuration

```bash
terraform apply
```

## What Gets Created

This example creates:

### Azure Resources
- **Azure Key Vault**: Stores MySQL credentials securely
- **Azure Function App**: Infrastructure for VA configuration
- **Storage Account**: Required by Azure Function
- **App Service Plan**: Consumption tier for Function App
- **Managed Identity**: For secure access to Key Vault

### Guardium Configuration
- **Datasource Registration**: Registers MySQL server in Guardium
- **VA Assessment Schedule**: Configures when scans run
- **Notification Configuration**: Sets up email alerts for findings

## Configuration Details

### Azure MySQL Server

The example requires an existing Azure MySQL Flexible Server. You need to provide:
- Server FQDN (e.g., `server-name.mysql.database.azure.com`)
- Port (default: 3306)
- Database name
- Admin username and password

### VA User

The Azure Function will create a `sqlguard` user in the MySQL database with the necessary permissions for vulnerability assessment. You need to provide:
- Username (default: `sqlguard`)
- Password (must be strong and secure)

### Vulnerability Assessment Schedule

Configure when VA scans should run:
- `assessment_schedule`: daily, weekly, or monthly
- `assessment_day`: Day of week (for weekly) or day of month (for monthly)
- `assessment_time`: Time in 24-hour format (e.g., "02:00")

### Notifications

Configure email notifications for assessment results:
- `enable_notifications`: Enable/disable notifications
- `notification_emails`: List of email addresses
- `notification_severity`: Minimum severity level (HIGH, MED, LOW, NONE)

## Outputs

After successful deployment, the following outputs are available:

```bash
terraform output
```

Outputs include:
- `function_app_name`: Name of the Azure Function App
- `function_app_id`: ID of the Function App
- `key_vault_name`: Name of the Key Vault
- `sqlguard_username`: Username for the Guardium VA user
- `va_config_completed`: Status message

## Function Code Deployment

**Important**: This Terraform configuration creates the infrastructure only. You need to deploy the actual function code separately.

### Option 1: Using Azure CLI

```bash
# Navigate to your function code directory
cd path/to/function/code

# Deploy to Azure
func azure functionapp publish <function-app-name>
```

### Option 2: Using GitHub Actions

Set up a CI/CD pipeline to automatically deploy function code on commits.

### Option 3: Manual Deployment

1. Package your function code
2. Upload via Azure Portal
3. Configure function triggers

### Function Code Requirements

The function should:
1. Retrieve credentials from Key Vault using Managed Identity
2. Connect to the MySQL server
3. Create the `sqlguard` user with appropriate permissions:

```sql
CREATE USER 'sqlguard'@'%' IDENTIFIED BY 'password';
GRANT SELECT, SHOW VIEW ON *.* TO 'sqlguard'@'%';
GRANT PROCESS ON *.* TO 'sqlguard'@'%';
FLUSH PRIVILEGES;
```

## Clean Up

To remove all resources created by this example:

```bash
terraform destroy
```

**Note**: This will not delete the Azure MySQL server itself (created by the deployment script).

## Cost Considerations

### Azure Resources
- **Key Vault**: ~$0.03/10,000 operations
- **Function App (Consumption)**: First 1M executions free
- **Storage Account**: ~$0.02/GB/month

**Estimated additional cost**: < $5/month

### Existing Resources
The Azure MySQL server cost depends on the SKU chosen in the deployment script.

## Security Best Practices

1. **Use Strong Passwords**: Never use default or simple passwords
2. **Secure Credentials**: All credentials stored in Key Vault
3. **Managed Identity**: Function App uses managed identity (no hardcoded secrets)
4. **SSL/TLS**: Enabled by default for MySQL connections
5. **Regular Scans**: Configure appropriate VA scan schedules
6. **Monitor Alerts**: Review notification emails promptly

## Troubleshooting

### Function App Deployment Fails

1. Check Azure CLI authentication: `az account show`
2. Verify resource group exists
3. Ensure Key Vault name is globally unique
4. Check Azure subscription limits

### Cannot Connect to MySQL

1. Verify MySQL server is running
2. Check firewall rules allow Azure services
3. Confirm credentials are correct
4. Test connection manually:
   ```bash
   mysql -h <server-fqdn> -u <username> -p <database>
   ```

### VA Assessment Not Running

1. Verify datasource is registered in Guardium
2. Check assessment schedule configuration
3. Review Guardium logs for errors
4. Ensure `sqlguard` user has correct permissions

### Key Vault Access Issues

1. Verify Managed Identity is enabled on Function App
2. Check Key Vault access policies
3. Ensure Function App has "Get" and "List" secret permissions

## Integration with Deployment Script

This example is designed to work with the Azure MySQL deployment script:

```bash
# 1. Deploy MySQL server
cd ../../scripts/azure-mysql-deployment
terraform apply

# 2. Note the outputs (server name, resource group, etc.)
terraform output

# 3. Use those values in this example
cd ../../examples/azure-mysql
# Edit terraform.tfvars with the output values
terraform apply
```

## Next Steps

After successful deployment:

1. **Deploy Function Code**: Deploy the actual VA configuration function
2. **Test Connection**: Verify the function can connect to MySQL
3. **Run Initial Scan**: Trigger a manual VA scan in Guardium
4. **Review Results**: Check Guardium dashboard for findings
5. **Configure Alerts**: Set up additional notification channels if needed

## Example Function Code

See the `modules/azure-mysql/files/` directory for example function code (to be created).

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0