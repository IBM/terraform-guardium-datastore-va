# Couchbase Capella VA Configuration Example

This example demonstrates how to configure Vulnerability Assessment (VA) for Couchbase Capella using Terraform.

## Overview

This example:
1. Deploys a Lambda function to configure the VA user in Couchbase Capella
2. Stores credentials in AWS Secrets Manager
3. Registers the Couchbase Capella cluster as a datasource in Guardium
4. Configures vulnerability assessment schedule and notifications

## Prerequisites

### 1. Couchbase Capella Cluster
- Active Couchbase Capella cluster
- Admin credentials with user management permissions
- Bucket created for VA assessment
- Cluster endpoint and REST API endpoint available

### 2. AWS Infrastructure
- VPC with private subnets
- **NAT Gateway for internet access** (required for Couchbase Capella cloud service)
- Appropriate IAM permissions to create:
  - Secrets Manager secrets
  - Lambda functions
  - IAM roles and policies
  - VPC endpoints
  - Security groups

### 3. Guardium Data Protection
- Guardium instance accessible
- Admin credentials
- OAuth client credentials (generate via: `grdapi register_oauth_client client_id=client1 grant_types=password`)
- **AWS Secrets Manager configuration created in Guardium** (see below)

### 4. AWS Secrets Manager Configuration in Guardium

**CRITICAL**: You must create an AWS Secrets Manager configuration in Guardium **before** running Terraform.

Steps:
1. Log into Guardium UI
2. Navigate to: **Setup → Tools and Views → Secrets Management**
3. Click **Add → AWS Secrets Manager**
4. Configure with your AWS credentials and region
5. Save with a memorable name (e.g., "aws-prod", "aws-dev")
6. Use that exact name in `terraform.tfvars` for `aws_secrets_manager_config_name`

## Phase 1 Integration (Optional)

This example can integrate with Phase 1 Couchbase Capella infrastructure deployment:

```hcl
# Uncomment in main.tf to use Phase 1 outputs
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../../../scripts/couchbase-capella-deployment/terraform.tfstate"
  }
}
```

## Usage

### Step 1: Copy Example Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit terraform.tfvars

Update the following required values:

```hcl
# Couchbase Capella
cluster_endpoint  = "cb.abc123.cloud.couchbase.com"
bucket_name       = "production-bucket"
admin_username    = "admin"
admin_password    = "your-secure-password" # pragma: allowlist secret
connection_string = "couchbases://cb.abc123.cloud.couchbase.com"
rest_api_endpoint = "https://cb.abc123.cloud.couchbase.com:18091"

# AWS
vpc_id     = "vpc-xxxxxxxxxxxxx"
subnet_ids = ["subnet-xxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyy"]

# Guardium
gdp_server                      = "guardium.example.com"
gdp_username                    = "admin"
gdp_password                    = "your-guardium-password" # pragma: allowlist secret
client_secret                   = "your-client-secret" # pragma: allowlist secret
aws_secrets_manager_config_name = "aws-prod"  # Must exist in Guardium

# VA User
sqlguard_password = "your-sqlguard-password" # pragma: allowlist secret

# Notifications
notification_emails = ["security@example.com"]
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review Plan

```bash
terraform plan
```

Expected resources (~10):
- 1 AWS Secrets Manager secret
- 1 Secret version
- 1 IAM role
- 1 IAM policy
- 1 IAM policy attachment
- 2 Security groups (Lambda + VPC endpoint)
- 1 VPC endpoint
- 1 Lambda function
- 1 Lambda invocation (gdp-middleware-helper)

### Step 5: Apply Configuration

```bash
terraform apply
```

### Step 6: Verify Deployment

#### Check Lambda Execution
```bash
# Get Lambda function name
FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# View Lambda logs
aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

#### Verify VA User in Couchbase
```bash
# Get credentials
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

#### Verify Guardium Datasource
```bash
# Check datasource registered
curl -k -X GET "https://$GDP_SERVER:8443/restAPI/datasources" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.[] | select(.name=="couchbase-capella-production-va")'
```

## What Gets Created

### AWS Resources

1. **Secrets Manager Secret**
   - Name: `{name_prefix}-couchbase-capella-va-credentials`
   - Contains: Admin credentials, VA user credentials, connection details

2. **Lambda Function**
   - Name: `{name_prefix}-couchbase-capella-va-config`
   - Runtime: Python 3.11
   - Purpose: Create/update VA user in Couchbase Capella

3. **IAM Role & Policy**
   - Lambda execution role
   - Permissions for CloudWatch Logs, Secrets Manager, VPC networking

4. **Security Groups**
   - Lambda security group (allows all outbound)
   - VPC endpoint security group (allows HTTPS from Lambda)

5. **VPC Endpoint**
   - Service: Secrets Manager
   - Type: Interface
   - Private DNS enabled

### Couchbase Capella Resources

1. **VA User (sqlguard)**
   - Roles:
     - `data_reader[bucket_name]` - Read data from bucket
     - `query_select[bucket_name]` - Execute SELECT queries
     - `query_system_catalog` - Access system catalog

### Guardium Resources

1. **Datasource Registration**
   - Type: "Couchbase Capella"
   - Connection details from Secrets Manager
   - VA schedule configured

2. **Vulnerability Assessment**
   - Schedule: Weekly (configurable)
   - Notifications: Email alerts for findings

## Networking Requirements

### Internet Access Required

Couchbase Capella is a cloud-hosted service. Your Lambda function needs internet access:

1. **Deploy Lambda in private subnets**
2. **Ensure subnets have NAT Gateway**
3. **Route table has route to NAT Gateway**

Example route table:
```
Destination     Target
10.0.0.0/16     local
0.0.0.0/0       nat-xxxxxxxxxxxxx
```

### Security Groups

- **Lambda SG**: Allows all outbound traffic (0.0.0.0/0)
- **VPC Endpoint SG**: Allows HTTPS (443) from Lambda SG

## Troubleshooting

### Lambda Cannot Connect to Couchbase Capella

**Symptom**: Lambda times out or connection refused

**Solutions**:
1. Verify subnets have NAT Gateway
2. Check route table has route to NAT Gateway
3. Verify Lambda security group allows outbound traffic
4. Test connectivity from EC2 instance in same subnet:
   ```bash
   curl -v https://cb.abc123.cloud.couchbase.com:18091/pools/default
   ```

### User Creation Fails

**Symptom**: Lambda returns error creating user

**Solutions**:
1. Verify admin credentials are correct
2. Check admin user has user management permissions
3. Verify REST API endpoint is correct
4. Review Lambda logs for specific error:
   ```bash
   aws logs tail /aws/lambda/$FUNCTION_NAME --follow
   ```

### Secrets Manager Access Denied

**Symptom**: Lambda cannot retrieve secret

**Solutions**:
1. Verify VPC endpoint for Secrets Manager exists
2. Check Lambda IAM role has GetSecretValue permission
3. Verify security group allows HTTPS to VPC endpoint
4. Check secret exists in correct region

### Guardium Datasource Registration Fails

**Symptom**: Error Code 113 or datasource not created

**Solutions**:
1. **Verify AWS Secrets Manager config exists in Guardium**
2. Check config name matches exactly (case-sensitive)
3. Verify Guardium can reach AWS Secrets Manager
4. Test config in Guardium UI first

### Error Code 23: Invalid Value

**Symptom**: Guardium rejects datasource type

**Solutions**:
1. Verify datasource type is exactly "Couchbase Capella"
2. Check Guardium version supports Couchbase Capella
3. Test with Guardium API to discover valid types:
   ```bash
   curl -X POST "https://$GDP_SERVER:8443/restAPI/datasource" \
     -d '{"type": "INVALID"}' | jq '.message'
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
- **Note**: Guardium datasource must be removed manually from Guardium UI

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_endpoint` | Couchbase Capella cluster endpoint |
| `bucket_name` | Bucket name |
| `lambda_function_name` | Lambda function name |
| `lambda_function_arn` | Lambda function ARN |
| `secret_arn` | Secrets Manager secret ARN |
| `secret_name` | Secrets Manager secret name |
| `gdp_datasource_name` | Guardium datasource name |
| `gdp_datasource_type` | Guardium datasource type |
| `gdp_vulnerability_assessment_enabled` | VA enabled status |
| `gdp_assessment_schedule` | VA schedule |

## Security Considerations

1. **Credentials**: All credentials stored encrypted in Secrets Manager
2. **Network Isolation**: Lambda runs in VPC with controlled egress
3. **Least Privilege**: VA user has minimal read-only permissions
4. **Audit Trail**: All Lambda executions logged to CloudWatch
5. **Secret Rotation**: Consider implementing secret rotation for production

## Next Steps

1. **Test VA Scan**: Trigger manual scan in Guardium UI
2. **Review Results**: Check vulnerability findings
3. **Configure Alerts**: Set up additional notification channels
4. **Schedule Scans**: Adjust assessment schedule as needed
5. **Monitor Logs**: Set up CloudWatch alarms for Lambda failures

## Support

For issues or questions:
- Check Lambda logs: `aws logs tail /aws/lambda/$FUNCTION_NAME`
- Review Guardium logs
- Verify all prerequisites are met
- Consult Guardium documentation for datasource configuration

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
