# AWS RDS MySQL with Guardium Vulnerability Assessment Example

This example demonstrates how to configure an existing AWS RDS MySQL instance for Guardium Vulnerability Assessment (VA) and connect it to Guardium Data Protection (GDP).

## Overview

This example performs the following steps:

1. **Configure VA on RDS MySQL**: Creates the necessary `sqlguard` user and grants required permissions for Guardium VA using a Lambda function
2. **Register with Guardium**: Connects the RDS MySQL instance to Guardium Data Protection and configures vulnerability assessment schedules

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC                                    │  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │  Lambda Function│────────▶│  RDS MySQL           │   │  │
│  │  │  (VA Config)    │         │  Instance            │   │  │
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

1. **Existing RDS MySQL Instance**:
   - MySQL version 5.7 or above
   - Instance endpoint accessible from the VPC subnets
   - Master user credentials with superuser privileges

2. **AWS Infrastructure**:
   - VPC with private subnets
   - Subnets with connectivity to the RDS instance
   - Security groups allowing Lambda to connect to MySQL (port 3306)

3. **Guardium Data Protection**:
   - Guardium server accessible from your network
   - Admin credentials for Guardium
   - OAuth client credentials (generated using `grdapi register_oauth_client`)

4. **Terraform**:
   - Terraform >= 1.0.0
   - AWS provider >= 5.0
   - Appropriate AWS credentials configured

## Usage

### Step 1: Find Required AWS Resource IDs

Before configuring variables, you need to gather information about your RDS MySQL instance's network configuration.

#### Find VPC ID, Subnets, and Security Group

Use the following AWS CLI commands to retrieve the required information from your RDS instance:

```bash
# Set your RDS instance identifier and region
INSTANCE_ID="your-mysql-instance-name"
REGION="us-east-1"

# Get the master username
aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].MasterUsername' \
  --output text

# Get the DB subnet group name
SUBNET_GROUP=$(aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].DBSubnetGroup.DBSubnetGroupName' \
  --output text)

# Get VPC ID and Subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name $SUBNET_GROUP \
  --region $REGION \
  --query 'DBSubnetGroups[0].{VpcId:VpcId,Subnets:Subnets[*].SubnetIdentifier}' \
  --output json

# Get Security Group ID
aws rds describe-db-instances \
  --db-instance-identifier $INSTANCE_ID \
  --region $REGION \
  --query 'DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId' \
  --output text
```

**Example output:**
```
Master Username: admin
{
    "VpcId": "vpc-xxxxxx",
    "Subnets": [
        "subnet-xxxxxxx",
        "subnet-xxxxxxx"
    ]
}
Security Group ID: sg-xxxxxx
```

#### Alternative: Using AWS Console

1. **Master Username**:
   - Go to RDS Console → Databases → Select your MySQL instance
   - Under "Configuration" tab, note the "Master username"

2. **VPC and Subnets**:
   - In the same instance details page
   - Under "Connectivity & security" tab, note the VPC ID
   - Click on the subnet group name to see the subnet IDs

3. **Security Group**:
   - In the same "Connectivity & security" tab
   - Note the security group ID under "VPC security groups"

### Step 2: Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values (use values from Step 1):

```hcl
# RDS MySQL Configuration
db_host     = "your-mysql-instance.xxxxx.us-east-1.rds.amazonaws.com"
db_username = "admin"  # Use the master username from Step 1
db_password = "your-secure-password"

# Network Configuration (use values from Step 1)
vpc_id                = "vpc-xxxxxxx"
subnet_ids            = ["subnet-xxxxxxx", "subnet-xxxxxx"]
db_security_group_id  = "sg-xxxxxx"

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "your-guardium-password"
client_secret = "your-client-secret"

# VA User Configuration
sqlguard_password = "your-sqlguard-password"
```

**Important Notes:**
- The `db_security_group_id` is required so Terraform can automatically add an ingress rule allowing the Lambda function to connect to MySQL on port 3306
- Use the actual master username from your RDS instance (found in Step 1)
- Ensure you have the correct master password for your RDS instance

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Plan

```bash
terraform plan
```

### Step 5: Apply the Configuration

```bash
terraform apply
```

### Step 6: Verify the Configuration

After successful deployment, verify:

1. **Lambda Function**: Check that the Lambda function executed successfully in AWS CloudWatch Logs
2. **MySQL User**: Connect to MySQL and verify the `sqlguard` user exists:
   ```sql
   SELECT User FROM mysql.user WHERE User = 'sqlguard';
   ```
3. **Guardium Registration**: Log into Guardium and verify the datasource appears in the datasource list
4. **VA Schedule**: Check that the vulnerability assessment schedule is configured

## What Gets Created

This example creates the following resources:

### AWS Resources

1. **Lambda Function**: Executes SQL commands to configure VA user on MySQL
2. **IAM Role & Policy**: Permissions for Lambda to access Secrets Manager and create network interfaces
3. **Security Groups**: 
   - Lambda security group (allows outbound to MySQL)
   - Secrets Manager VPC endpoint security group
4. **Security Group Rule**: Automatically adds ingress rule to RDS security group allowing Lambda access on port 3306
5. **Secrets Manager Secret**: Stores MySQL and sqlguard credentials securely
6. **VPC Endpoint**: Allows Lambda to access Secrets Manager from private subnets

### Guardium Configuration

1. **Datasource Registration**: Registers MySQL instance in Guardium
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

### MySQL-Specific Considerations

1. **Instance Endpoint**: Use the instance endpoint for the `db_host` variable
2. **Parameter Group**: Ensure the MySQL parameter group allows user creation
3. **Multi-AZ**: The Lambda function should be deployed in subnets that can reach the RDS instance

### Security Best Practices

1. **Credentials Management**:
   - Never commit `terraform.tfvars` to version control
   - Use environment variables or AWS Secrets Manager for sensitive values
   - Rotate passwords regularly

2. **Network Security**:
   - The module automatically adds a security group rule allowing Lambda to connect to MySQL
   - MySQL security group only allows connections from Lambda security group (port 3306)
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
   - Lambda security group allows outbound to MySQL port (3306)
   - MySQL security group allows inbound from Lambda security group (automatically configured by Terraform)
   - Subnets have route to NAT Gateway or VPC endpoints

#### Guardium Connection Fails

1. Verify Guardium server is accessible from your network
2. Check OAuth client credentials are correct
3. Verify Guardium user has appropriate permissions

#### VPC Endpoint Already Exists Error

If you encounter an error like "VpcEndpoint already exists in this VPC", it means a Secrets Manager VPC endpoint already exists in your VPC. To resolve this:

1. **Find the existing VPC endpoint ID**:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters Name=vpc-id,Values=<your-vpc-id> \
              Name=service-name,Values=com.amazonaws.<your-region>.secretsmanager \
     --region <your-region> \
     --query 'VpcEndpoints[].VpcEndpointId' \
     --output text
   ```

   Example:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters Name=vpc-id,Values=vpc-xxxxxxxx \
              Name=service-name,Values=com.amazonaws.us-east-2.secretsmanager \
     --region us-east-2 \
     --query 'VpcEndpoints[].VpcEndpointId' \
     --output text
   ```

2. **Import the existing endpoint into Terraform state**:
   ```bash
   terraform import \
     'module.mysql_va_config.aws_vpc_endpoint.secretsmanager' \
     <vpc-endpoint-id>
   ```

   Example:
   ```bash
   terraform import \
     'module.mysql_va_config.aws_vpc_endpoint.secretsmanager' \
     vpce-xxxxxxxxx
   ```

3. **Re-run terraform apply**:
   ```bash
   terraform apply
   ```

#### VA User Creation Fails

1. Ensure master user has superuser privileges
2. Check MySQL parameter group allows user creation
3. Verify RDS instance is not in maintenance mode

## Cleanup

To remove all resources created by this example:

```bash
terraform destroy
```

**Note**: This will:
- Delete the Lambda function and associated resources
- Remove the Secrets Manager secret (immediate deletion)
- Remove the security group rule from the RDS security group
- Unregister the datasource from Guardium
- **NOT** delete the RDS MySQL instance itself (it's managed separately)
- **NOT** delete the `sqlguard` user from MySQL (manual cleanup required)

To manually remove the `sqlguard` user from MySQL:

```sql
DROP USER IF EXISTS 'sqlguard'@'%';
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
2. Review the [module documentation](../../modules/aws-rds-mysql/README.md)
3. Open an issue in the GitHub repository

## License

This example is provided under the same license as the main module.
