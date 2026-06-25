# Couchbase Capella VA Configuration Module

This Terraform module configures Vulnerability Assessment (VA) for Couchbase Capella by:
1. Storing Couchbase Capella credentials in AWS Secrets Manager
2. Deploying a Lambda function to create/configure the VA user
3. Providing outputs for Guardium datasource integration

## Prerequisites

### AWS Infrastructure
- VPC with private subnets
- NAT Gateway for internet access (required for Couchbase Capella cloud service)
- Appropriate IAM permissions to create:
  - Secrets Manager secrets
  - Lambda functions
  - IAM roles and policies
  - VPC endpoints
  - Security groups

### Couchbase Capella
- Active Couchbase Capella cluster
- Admin credentials with permissions to create users
- Bucket created for VA assessment
- Cluster endpoint and REST API endpoint available

### Guardium
- AWS Secrets Manager configuration created in Guardium
- Guardium Data Protection instance accessible
- GDP OAuth credentials available

## Usage

```hcl
module "couchbase_capella_va_config" {
  source = "../../modules/couchbase-capella"

  # Resource naming
  name_prefix = "guardium-test"

  # Couchbase Capella connection details
  cluster_endpoint  = "cb.abc123.cloud.couchbase.com"
  bucket_name       = "test-bucket"
  admin_username    = "admin"
  admin_password    = var.admin_password
  connection_string = "couchbases://cb.abc123.cloud.couchbase.com"
  rest_api_endpoint = "https://cb.abc123.cloud.couchbase.com:18091"
  cluster_port      = 18091

  # VA user credentials
  sqlguard_username = "sqlguard"
  sqlguard_password = var.sqlguard_password

  # AWS networking
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  aws_region = "us-east-1"

  # Optional
  guardium_hostname = "guardium.example.com"

  tags = {
    Environment = "test"
    Purpose     = "guardium-va"
  }
}
```

## Integration with Phase 1 Infrastructure

This module is designed to work with the Couchbase Capella infrastructure deployed in Phase 1:

```hcl
# Reference Phase 1 deployment state
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../../../scripts/couchbase-capella-deployment/terraform.tfstate"
  }
}

module "couchbase_capella_va_config" {
  source = "../../modules/couchbase-capella"

  name_prefix       = "guardium-test"
  cluster_endpoint  = data.terraform_remote_state.infrastructure.outputs.cluster_endpoint
  bucket_name       = data.terraform_remote_state.infrastructure.outputs.bucket_name
  admin_username    = data.terraform_remote_state.infrastructure.outputs.admin_username
  admin_password    = data.terraform_remote_state.infrastructure.outputs.admin_password
  connection_string = data.terraform_remote_state.infrastructure.outputs.connection_string
  rest_api_endpoint = data.terraform_remote_state.infrastructure.outputs.rest_api_endpoint

  # ... other variables
}
```

## What This Module Does

### 1. Secrets Manager Secret
Creates an AWS Secrets Manager secret containing:
- Admin credentials for Couchbase Capella
- Cluster connection details
- VA user credentials (sqlguard)
- Bucket information

### 2. Lambda Function
Deploys a Python Lambda function that:
- Retrieves credentials from Secrets Manager
- Connects to Couchbase Capella via REST API
- Creates or updates the VA user (sqlguard)
- Assigns appropriate roles for vulnerability assessment:
  - `data_reader[bucket_name]` - Read data from bucket
  - `query_select[bucket_name]` - Execute SELECT queries
  - `query_system_catalog` - Access system catalog for metadata

### 3. VPC Configuration
- Creates Lambda security group with outbound internet access
- Creates VPC endpoint for Secrets Manager (private access)
- Configures security group for VPC endpoint

### 4. IAM Permissions
- Lambda execution role
- Permissions for CloudWatch Logs
- Permissions for Secrets Manager access
- Permissions for VPC networking

## Couchbase Capella Permissions

The VA user (sqlguard) is created with the following roles:

| Role | Purpose |
|------|---------|
| `data_reader[bucket_name]` | Read documents from the specified bucket |
| `query_select[bucket_name]` | Execute SELECT queries on the bucket |
| `query_system_catalog` | Access system catalog for metadata queries |

These roles provide read-only access necessary for vulnerability assessment without allowing data modification.

## Networking Requirements

### VPC Subnets
- Must have internet access via NAT Gateway
- Couchbase Capella is a cloud service requiring internet connectivity
- Lambda needs to reach:
  - Couchbase Capella cluster (HTTPS/18091)
  - AWS Secrets Manager (via VPC endpoint)

### Security Groups
- Lambda security group allows all outbound traffic
- VPC endpoint security group allows HTTPS (443) from Lambda

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_endpoint | Couchbase Capella cluster endpoint | string | - | yes |
| bucket_name | Couchbase bucket name | string | - | yes |
| admin_username | Admin username | string | - | yes |
| admin_password | Admin password | string | - | yes |
| connection_string | Full connection string | string | - | yes |
| rest_api_endpoint | REST API endpoint | string | - | yes |
| cluster_port | Cluster port | number | 18091 | no |
| sqlguard_username | VA user username | string | "sqlguard" | no |
| sqlguard_password | VA user password | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs | list(string) | - | yes |
| aws_region | AWS region | string | - | yes |
| name_prefix | Resource name prefix | string | - | yes |
| guardium_hostname | Guardium hostname | string | "" | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_name | Lambda function name |
| lambda_function_arn | Lambda function ARN |
| secret_arn | Secrets Manager secret ARN |
| secret_name | Secrets Manager secret name |
| lambda_security_group_id | Lambda security group ID |
| vpc_endpoint_id | VPC endpoint ID |
| guardium_datasource_config | Guardium datasource configuration (sensitive) |

## Lambda Function Execution

The Lambda function is automatically invoked during Terraform apply via the `gdp-middleware-helper` provider. It:

1. Retrieves credentials from Secrets Manager
2. Verifies connection to Couchbase Capella
3. Checks if VA user exists
4. Creates or updates VA user with appropriate roles
5. Verifies user configuration
6. Returns success/failure status

### Lambda Logs

View Lambda execution logs:
```bash
aws logs tail /aws/lambda/<function-name> --follow
```

## Troubleshooting

### Lambda Cannot Connect to Couchbase Capella

**Symptom**: Lambda times out or fails to connect

**Solutions**:
1. Verify subnets have NAT Gateway for internet access
2. Check Lambda security group allows outbound traffic
3. Verify Couchbase Capella endpoint is correct
4. Check Couchbase Capella allows connections from your IP range

### User Creation Fails

**Symptom**: Lambda returns error creating user

**Solutions**:
1. Verify admin credentials have user management permissions
2. Check Couchbase Capella REST API endpoint is accessible
3. Review Lambda logs for specific error messages
4. Verify bucket name exists in cluster

### Secrets Manager Access Denied

**Symptom**: Lambda cannot retrieve secret

**Solutions**:
1. Verify VPC endpoint for Secrets Manager is created
2. Check Lambda IAM role has GetSecretValue permission
3. Verify security group allows HTTPS to VPC endpoint
4. Check secret exists in correct region

## Testing

### Verify Lambda Execution
```bash
# Get Lambda function name
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# Invoke Lambda manually
aws lambda invoke \
  --function-name $FUNCTION_NAME \
  --payload '{}' \
  response.json

# Check response
cat response.json | jq
```

### Verify VA User in Couchbase
```bash
# Get credentials from Secrets Manager
SECRET_ARN=$(terraform output -raw secret_arn)
CREDENTIALS=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text)

# Extract values
ENDPOINT=$(echo $CREDENTIALS | jq -r '.rest_api_endpoint')
ADMIN_USER=$(echo $CREDENTIALS | jq -r '.username')
ADMIN_PASS=$(echo $CREDENTIALS | jq -r '.password')
VA_USER=$(echo $CREDENTIALS | jq -r '.sqlguard_username')

# Check VA user exists
curl -u $ADMIN_USER:$ADMIN_PASS \
  "$ENDPOINT/settings/rbac/users/local/$VA_USER"
```

## Cleanup

```bash
terraform destroy -auto-approve
```

This will:
- Delete Lambda function
- Delete Secrets Manager secret (immediate deletion)
- Remove VPC endpoint
- Delete security groups
- Remove IAM roles and policies

## Security Considerations

1. **Credentials Storage**: All credentials stored in Secrets Manager with encryption at rest
2. **Network Isolation**: Lambda runs in VPC with controlled egress
3. **Least Privilege**: VA user has minimal read-only permissions
4. **Audit Trail**: All Lambda executions logged to CloudWatch
5. **Secret Rotation**: Consider implementing secret rotation for production

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
