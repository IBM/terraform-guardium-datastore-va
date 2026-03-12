# AWS Aurora MySQL with Vulnerability Assessment Example

This example demonstrates how to configure Vulnerability Assessment (VA) for an AWS Aurora MySQL cluster using Terraform.

## Overview

This example:
1. Configures VA on an existing Aurora MySQL cluster by creating a Lambda function that sets up the necessary database users and permissions
2. Registers the Aurora MySQL cluster as a datasource in Guardium Data Protection (GDP)
3. Configures vulnerability assessment schedules and notifications

## Prerequisites

- An existing AWS Aurora MySQL cluster
- VPC and subnets where the Aurora MySQL cluster is deployed
- Security group ID of the Aurora MySQL cluster
- Master database credentials with sufficient privileges
- A Guardium Data Protection instance
- Guardium OAuth client credentials (see [Preparing Guardium](../../docs/preparing-guardium.md))

## Usage

### Step 1: Find Required AWS Resource IDs

Before configuring variables, you need to gather information about your Aurora MySQL cluster's network configuration.

#### Find VPC ID, Subnets, and Security Group

Use the following AWS CLI commands to retrieve the required information from your Aurora MySQL cluster:

```bash
# Set your Aurora cluster identifier and region
CLUSTER_ID="your-aurora-cluster-name"
REGION="us-east-1"

# Get the DB subnet group name
SUBNET_GROUP=$(aws rds describe-db-clusters \
  --db-cluster-identifier $CLUSTER_ID \
  --region $REGION \
  --query 'DBClusters[0].DBSubnetGroup' \
  --output text)

# Get VPC ID and Subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name $SUBNET_GROUP \
  --region $REGION \
  --query 'DBSubnetGroups[0].{VpcId:VpcId,Subnets:Subnets[*].SubnetIdentifier}' \
  --output json

# Get Security Group ID
aws rds describe-db-clusters \
  --db-cluster-identifier $CLUSTER_ID \
  --region $REGION \
  --query 'DBClusters[0].VpcSecurityGroups[*].VpcSecurityGroupId' \
  --output text
```

**Example output:**
```json
{
    "VpcId": "vpc-95525af1",
    "Subnets": [
        "subnet-ed97e39b",
        "subnet-fac680c7"
    ]
}
Security Group ID: sg-e415589c
```

#### Alternative: Using AWS Console

1. **VPC and Subnets**:
   - Go to RDS Console → Databases → Select your Aurora cluster
   - Under "Connectivity & security" tab, note the VPC ID
   - Click on the subnet group name to see the subnet IDs

2. **Security Group**:
   - In the same "Connectivity & security" tab
   - Note the security group ID under "VPC security groups"

### Step 2: Configure Variables

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and fill in your values (use values from Step 1):
   - AWS region and resource names
   - Aurora MySQL cluster connection details
   - **Network Configuration** (use values from Step 1):
     ```hcl
     vpc_id               = "vpc-95525af1"      # From Step 1
     subnet_ids           = ["subnet-ed97e39b", "subnet-fac680c7"]  # From Step 1
     db_security_group_id = "sg-e415589c"      # From Step 1
     ```
   - Guardium server details and credentials
   - VA user credentials
   - Assessment schedule and notification preferences

**Important Notes:**
- The `db_security_group_id` is required so Terraform can automatically add an ingress rule allowing the Lambda function to connect to Aurora MySQL on port 3306
- Ensure you have the correct master username and password for your Aurora cluster

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Planned Changes

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
2. **Aurora MySQL User**: Connect to Aurora MySQL and verify the `sqlguard` user exists:
   ```sql
   SELECT User FROM mysql.user WHERE User = 'sqlguard';
   ```
3. **Guardium Registration**: Log into Guardium and verify the datasource appears in the datasource list
4. **VA Schedule**: Check that the vulnerability assessment schedule is configured

## What Gets Created

This example creates:
- AWS Lambda function for VA configuration
- IAM role and policy for Lambda execution
- AWS Secrets Manager secret for database credentials
- VPC endpoint for Secrets Manager
- Security groups for Lambda and VPC endpoint
- Security group rule to allow Lambda access to Aurora MySQL
- Guardium datasource registration
- VA assessment schedule configuration
- Notification configuration for assessment results

## Configuration Details

### Aurora MySQL Cluster

The example requires an existing Aurora MySQL cluster. You need to provide:
- Cluster endpoint hostname
- Port (default: 3306)
- Database name
- Master username and password

### VA User

The Lambda function creates a `sqlguard` user in the Aurora MySQL database with the necessary permissions for vulnerability assessment. You need to provide:
- Username (default: `sqlguard`)
- Password (must be strong and secure)



## Outputs

After successful deployment, the following outputs are available:
- `lambda_function_arn`: ARN of the Lambda function
- `lambda_function_name`: Name of the Lambda function
- `security_group_id`: Security group ID for the Lambda function
- `sqlguard_username`: Username for the Guardium VA user
- `va_config_completed`: Confirmation that VA configuration is complete
- `secrets_manager_secret_arn`: ARN of the Secrets Manager secret

## Clean Up

To remove all resources created by this example:
```bash
terraform destroy
```

## Notes

- The Lambda function is deployed in the same VPC as the Aurora MySQL cluster for secure communication
- All database credentials are stored securely in AWS Secrets Manager
- The `sqlguard` user is created with minimal required permissions for VA
- SSL/TLS is enabled by default for secure connections

## Troubleshooting

### Lambda Function Fails

If the Lambda function fails to execute:
1. Check CloudWatch Logs for the Lambda function
2. Verify the Aurora MySQL cluster is accessible from the Lambda subnets
3. Ensure the master database credentials are correct
4. Verify the security group rules allow Lambda to connect to Aurora MySQL

### VA Assessment Not Running

If vulnerability assessments are not running:
1. Verify the datasource is registered in Guardium
2. Check the assessment schedule configuration
3. Review Guardium logs for any errors

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0