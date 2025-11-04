# AWS Aurora PostgreSQL with Guardium Vulnerability Assessment Example

This example demonstrates how to configure an existing AWS Aurora PostgreSQL cluster for Guardium Vulnerability Assessment (VA) and connect it to Guardium Data Protection (GDP).

## Overview

This example performs the following steps:

1. **Configure VA on Aurora PostgreSQL**: Creates the necessary `sqlguard` user and grants required permissions for Guardium VA using a Lambda function
2. **Register with Guardium**: Connects the Aurora PostgreSQL cluster to Guardium Data Protection and configures vulnerability assessment schedules

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC                                    │  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │  Lambda Function│────────▶│  Aurora PostgreSQL   │   │  │
│  │  │  (VA Config)    │         │  Cluster             │   │  │
│  │  └────────┬────────┘         └──────────────────────┘   │  │
│  │           │                                              │  │
│  │           │                                              │  │
│  │  ┌────────▼────────┐         ┌──────────────────────┐   │  │
│  │  │  Secrets Manager│         │  VPC Endpoint        │   │  │
│  │  │  (Credentials)  │◀────────│  (Secrets Manager)   │   │  │
│  │  └─────────────────┘         └──────────────────────┘   │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
                    ┌──────────────────┐
                    │   Guardium Data  │
                    │   Protection     │
                    │   (GDP)          │
                    └──────────────────┘
```

## Prerequisites

Before using this example, ensure you have:

1. **Existing Aurora PostgreSQL Cluster**:
   - Aurora PostgreSQL version 10.x or above
   - Cluster endpoint accessible from the VPC subnets
   - Master user credentials with superuser privileges

2. **AWS Infrastructure**:
   - VPC with private subnets
   - Subnets with connectivity to the Aurora cluster
   - Security groups allowing Lambda to connect to Aurora (port 5432)

3. **Guardium Data Protection**:
   - Guardium server accessible from your network
   - Admin credentials for Guardium
   - OAuth client credentials (generated using `grdapi register_oauth_client`)

4. **Terraform**:
   - Terraform >= 1.0.0
   - AWS provider >= 5.0
   - Appropriate AWS credentials configured

## Usage

### Step 1: Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Aurora PostgreSQL Configuration
db_host     = "your-aurora-cluster.cluster-xxxxx.us-east-1.rds.amazonaws.com"
db_name     = "postgres"
db_username = "postgres"
db_password = "your-secure-password"

# Network Configuration
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "your-guardium-password"
client_secret = "your-client-secret"

# VA User Configuration
sqlguard_password = "your-sqlguard-password"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Review the Plan

```bash
terraform plan
```

### Step 4: Apply the Configuration

```bash
terraform apply
```

### Step 5: Verify the Configuration

After successful deployment, verify:

1. **Lambda Function**: Check that the Lambda function executed successfully in AWS CloudWatch Logs
2. **Aurora User**: Connect to Aurora and verify the `sqlguard` user exists:
   ```sql
   SELECT usename FROM pg_user WHERE usename = 'sqlguard';
   ```
3. **Guardium Registration**: Log into Guardium and verify the datasource appears in the datasource list
4. **VA Schedule**: Check that the vulnerability assessment schedule is configured

## What Gets Created

This example creates the following resources:

### AWS Resources

1. **Lambda Function**: Executes SQL commands to configure VA user on Aurora
2. **IAM Role & Policy**: Permissions for Lambda to access Secrets Manager and create network interfaces
3. **Security Groups**: 
   - Lambda security group (allows outbound to Aurora)
   - Secrets Manager VPC endpoint security group
4. **Secrets Manager Secret**: Stores Aurora and sqlguard credentials securely
5. **VPC Endpoint**: Allows Lambda to access Secrets Manager from private subnets

### Guardium Configuration

1. **Datasource Registration**: Registers Aurora cluster in Guardium
2. **VA Schedule**: Configures vulnerability assessment schedule
3. **Notifications**: Sets up email notifications for assessment results

## Outputs

After successful deployment, the following outputs are available:

```hcl
sqlguard_username          # Username for the Guardium VA user
lambda_function_arn        # ARN of the Lambda function
lambda_function_name       # Name of the Lambda function
security_group_id          # Security group ID for Lambda
va_config_completed        # VA configuration status
secrets_manager_secret_arn # ARN of the Secrets Manager secret
datasource_name            # Name of the datasource in Guardium
gdp_connection_status      # Connection status to Guardium
```

## Important Notes

### Aurora-Specific Considerations

1. **Cluster Endpoint**: Always use the cluster endpoint (not instance endpoints) for the `db_host` variable
2. **Aurora Serverless v2**: Ensure the cluster has sufficient capacity to handle Lambda connections
3. **Multi-AZ**: The Lambda function should be deployed in subnets that can reach all Aurora instances

### Security Best Practices

1. **Credentials Management**:
   - Never commit `terraform.tfvars` to version control
   - Use environment variables or AWS Secrets Manager for sensitive values
   - Rotate passwords regularly

2. **Network Security**:
   - Ensure Aurora security group only allows connections from Lambda security group
   - Use private subnets for Lambda deployment
   - Enable VPC Flow Logs for network monitoring

3. **IAM Permissions**:
   - Follow principle of least privilege
   - Review and audit IAM policies regularly

### Troubleshooting

#### Lambda Function Fails

1. Check CloudWatch Logs for the Lambda function:
   ```bash
   aws logs tail /aws/lambda/<function-name> --follow
   ```

2. Verify network connectivity:
   - Lambda security group allows outbound to Aurora port (5432)
   - Aurora security group allows inbound from Lambda security group
   - Subnets have route to NAT Gateway or VPC endpoints

#### Guardium Connection Fails

1. Verify Guardium server is accessible from your network
2. Check OAuth client credentials are correct
3. Verify Guardium user has appropriate permissions

#### VA User Creation Fails

1. Ensure master user has superuser privileges
2. Check Aurora parameter group allows user creation
3. Verify Aurora cluster is not in maintenance mode

## Cleanup

To remove all resources created by this example:

```bash
terraform destroy
```

**Note**: This will:
- Delete the Lambda function and associated resources
- Remove the Secrets Manager secret (immediate deletion)
- Unregister the datasource from Guardium
- **NOT** delete the Aurora cluster itself (it's managed separately)
- **NOT** delete the `sqlguard` user from Aurora (manual cleanup required)

To manually remove the `sqlguard` user from Aurora:

```sql
DROP USER IF EXISTS sqlguard;
DROP GROUP IF EXISTS gdmmonitor;
```

## Cost Considerations

This example incurs the following AWS costs:

- **Lambda**: Pay per invocation (one-time setup cost, minimal)
- **Secrets Manager**: ~$0.40/month per secret
- **VPC Endpoint**: ~$7.20/month for Secrets Manager endpoint
- **CloudWatch Logs**: Based on log retention and volume

## Support

For issues or questions:

1. Check the [main README](../../README.md) for general information
2. Review the [module documentation](../../modules/aws-aurora-postgresql/README.md)
3. Open an issue in the GitHub repository

## License

This example is provided under the same license as the main module.