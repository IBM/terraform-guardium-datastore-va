# AWS Neptune Vulnerability Assessment Configuration Module

This Terraform module configures AWS Neptune for Guardium Vulnerability Assessment (VA) by creating and configuring a VA user with appropriate permissions.

## Overview

The module performs the following actions:
1. Creates an AWS Lambda function to configure Neptune for VA
2. Stores Neptune credentials securely in AWS Secrets Manager
3. Creates necessary IAM roles and policies for Lambda execution
4. Sets up VPC networking for secure Lambda execution
5. Configures a VA user (sqlguard) in Neptune with required permissions

## Prerequisites

- AWS Neptune cluster already deployed
- VPC and subnets configured
- Appropriate AWS credentials with permissions to create Lambda functions, IAM roles, and Secrets Manager secrets
- The `gdp-middleware-helper` Terraform provider installed

## Usage

```hcl
module "neptune_va_config" {
  source = "../../modules/aws-neptune"

  name_prefix = "my-neptune-va"

  # Neptune Connection Details
  neptune_cluster_endpoint    = "my-neptune-cluster.cluster-xxxxx.us-east-1.neptune.amazonaws.com"
  neptune_cluster_port        = 8182
  neptune_cluster_identifier  = "my-neptune-cluster"
  db_username                 = "admin"
  db_password                 = "your-admin-password"

  # VA User Configuration
  sqlguard_username = "sqlguard"
  sqlguard_password = "your-sqlguard-password"

  # Network Configuration
  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]

  # General Configuration
  aws_region = "us-east-1"
  tags = {
    Environment = "production"
    Purpose     = "guardium-va"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| neptune_cluster_endpoint | Endpoint of the Neptune cluster | `string` | n/a | yes |
| neptune_cluster_port | Port for the Neptune cluster | `number` | `8182` | no |
| neptune_cluster_identifier | Identifier of the Neptune cluster | `string` | n/a | yes |
| db_username | Username for the Neptune database | `string` | n/a | yes |
| db_password | Password for the Neptune database | `string` | n/a | yes |
| sqlguard_username | Username for the Guardium VA user | `string` | `"sqlguard"` | no |
| sqlguard_password | Password for the sqlguard user | `string` | n/a | yes |
| vpc_id | ID of the VPC where Lambda will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for Lambda | `list(string)` | n/a | yes |
| aws_region | AWS region where resources will be created | `string` | n/a | yes |
| name_prefix | Prefix to use for resource names | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_name | Name of the Lambda function used for VA configuration |
| lambda_function_arn | ARN of the Lambda function |
| secret_arn | ARN of the Secrets Manager secret |
| secret_name | Name of the Secrets Manager secret |
| lambda_security_group_id | ID of the Lambda security group |
| vpc_endpoint_id | ID of the VPC endpoint for Secrets Manager |

## Notes

- The Lambda function requires network access to the Neptune cluster
- Ensure the Lambda security group can communicate with Neptune
- The VA user (sqlguard) is created with read-only permissions for vulnerability assessment
- Neptune uses Gremlin/SPARQL query languages, not SQL

---

## 🔧 Terraform Import Guide & Troubleshooting

### Common Terraform Import Scenarios

#### 1. VPC Endpoint for Secrets Manager Already Exists

**Issue**: VPC endpoint already existed with `private_dns_enabled = true`, causing a conflict.

**Error Message**:
```
Error: creating EC2 VPC Endpoint (com.amazonaws.us-west-2.secretsmanager):
operation error EC2: CreateVpcEndpoint, https response error StatusCode: 400,
api error InvalidParameter: private-dns-enabled cannot be set because there is
already a conflicting DNS domain for secretsmanager.us-west-2.amazonaws.com
in the VPC vpc-xxxxx
```

**Solution**: Import the existing VPC endpoint instead of creating a new one.

```bash
# Step 1: Find the existing VPC endpoint ID
aws ec2 describe-vpc-endpoints \
  --region us-west-2 \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
            "Name=service-name,Values=com.amazonaws.us-west-2.secretsmanager" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text

# Output example: vpce-03cc86d3c12bc7cc1

# Step 2: Import the VPC endpoint into Terraform state
terraform import module.neptune_va_config.aws_vpc_endpoint.secretsmanager vpce-03cc86d3c12bc7cc1
```

---

#### 2. AWS Secrets Manager Secret Scheduled for Deletion

**Issue**: Secret was scheduled for deletion, preventing creation of a new secret with the same name.

**Error Message**:
```
Error: creating Secrets Manager Secret (guardium-neptune-va-password):
operation error Secrets Manager: CreateSecret, https response error StatusCode: 400,
InvalidRequestException: You can't create this secret because a secret with this
name is already scheduled for deletion.
```

**Solution**: Restore the secret and import it into Terraform state.

```bash
# Step 1: Find the secret ARN (including those scheduled for deletion)
aws secretsmanager list-secrets \
  --region us-west-2 \
  --include-planned-deletion \
  --filters Key=name,Values=guardium-neptune-va-password \
  --query 'SecretList[0].[ARN,DeletedDate]' \
  --output text

# Output example:
# arn:aws:secretsmanager:us-west-2:123456789:secret:guardium-neptune-va-password-ABC123
# 2026-02-24T15:59:07.752000-05:00

# Step 2: Restore the secret
aws secretsmanager restore-secret \
  --secret-id arn:aws:secretsmanager:us-west-2:123456789:secret:guardium-neptune-va-password-ABC123 \
  --region us-west-2

# Step 3: Import the secret into Terraform state
terraform import module.neptune_va_config.aws_secretsmanager_secret.neptune_credentials \
  arn:aws:secretsmanager:us-west-2:123456789:secret:guardium-neptune-va-password-ABC123
```

---

### 📋 Configuration Issues & Solutions

#### Issue 1: "Value not in constant list" Error

**Error from Guardium API**:
```json
{
  "ErrorCode": "23",
  "ErrorMessage": "create_datasource: Wrong value: 'awsSecretsManagerConfigName' must be one of possible values. Value not in constant list.",
  "ValidParameterValues": ["your-config-name"]
}
```

**Cause**: The `aws_secrets_manager_config_name` value doesn't match any AWS Secrets Manager configuration in Guardium Data Protection (GDP).

**Solution**:

1. **Verify the configuration exists in GDP**:
   - Log into Guardium UI
   - Navigate to: **Setup** → **Tools and Views** → **Secrets Management**
   - Look for AWS Secrets Manager configurations
   - Note the exact configuration name (case-sensitive)

2. **Update your terraform.tfvars**:
   ```hcl
   # ❌ WRONG - Using encrypted or invalid name
   aws_secrets_manager_config_name = "xGRCCZy9DZPH+vFo6Wk8Apc1KpnCqM5sRCd23yrk"
   
   # ✅ CORRECT - Using actual config name from GDP
   aws_secrets_manager_config_name = "aws-prod-config"
   ```

3. **If no configuration exists, create one in GDP first**:
   - In Guardium UI: **Setup** → **Tools and Views** → **Secrets Management**
   - Click **Add** → **AWS Secrets Manager**
   - Configure with your AWS credentials and region
   - Save with a memorable name (e.g., "aws-prod", "aws-dev")

**⚠️ Important**: The AWS Secrets Manager configuration **MUST be created in Guardium Data Protection BEFORE** running Terraform.

---

#### Issue 2: "Cannot set external password type" Error

**Error from Guardium API**:
```json
{
  "ErrorCode": "113",
  "ErrorMessage": "create_datasource: Cannot set external password type. The datasource neptune-va is not using external password. Could not complete the operation"
}
```

**Cause**: You're providing external password configuration (AWS Secrets Manager, CyberArk, HashiCorp Vault) but `use_external_password = false`.

**Solution**: When using AWS Secrets Manager or any external password manager, you **MUST** set `use_external_password = true`.

**✅ Correct Configuration**:
```hcl
# When using AWS Secrets Manager
use_external_password           = true  # MUST be true
aws_secrets_manager_config_name = "aws-prod-config"
region                          = "us-east-1"
secret_name                     = "guardium/neptune/credentials"
```

**❌ Incorrect Configuration**:
```hcl
# This will cause error 113
use_external_password           = false  # Wrong!
aws_secrets_manager_config_name = "aws-prod-config"  # Conflict!
```

**Key Rule**: If you set ANY external password configuration (AWS Secrets Manager, CyberArk, HashiCorp Vault), you **MUST** set `use_external_password = true`.

### 🐛 Debugging & Verification

#### Verify Datasource Registration

1. **Check Terraform state**:
   ```bash
   terraform state show 'module.neptune_gdp_connection[0].guardium-data-protection_register_va_datasource.register_va_datasource'
   ```

2. **Check Guardium UI**:
   - Navigate to Data Sources or Vulnerability Assessment section
   - Look for your datasource name

3. **Enable debug logging**:
   ```bash
   TF_LOG=DEBUG terraform apply -auto-approve 2>&1 | tee terraform-debug.log
   grep "register data source response" terraform-debug.log
   ```

#### Common Issues Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| "Value not in constant list" | Verify AWS Secrets Manager config exists in GDP UI |
| "Cannot set external password type" | Set `use_external_password = true` |
| VPC endpoint conflict | Import existing endpoint with `terraform import` |
| Secret scheduled for deletion | Restore secret with `aws secretsmanager restore-secret` |
| Datasource already exists | Use different name or delete existing datasource |

---

### 📚 Additional Resources

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [AWS VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Guardium Data Protection API](https://www.ibm.com/docs/en/guardium)

---

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0