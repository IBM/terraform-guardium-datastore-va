# AWS Neptune with Vulnerability Assessment Example

This example demonstrates how to configure an AWS Neptune cluster for Guardium Vulnerability Assessment (VA).

## Overview

This example:
1. Configures a Neptune cluster for VA by creating necessary metadata
2. Registers the Neptune cluster as a data source in Guardium Data Protection
3. Enables vulnerability assessment with configurable schedules
4. Sets up email notifications for assessment results

## Prerequisites

- AWS Neptune cluster already deployed and accessible
- VPC and subnets configured for Lambda deployment
- Guardium Data Protection system deployed and accessible
- OAuth client credentials generated in Guardium (via `grdapi register_oauth_client`)
- Terraform >= 1.3
- AWS credentials configured
- The `gdp-middleware-helper` Terraform provider installed

## Neptune-Specific Considerations

Neptune is a graph database that differs from traditional SQL databases:
- Uses **Gremlin** (property graph) or **SPARQL** (RDF graph) query languages
- Does not have traditional user management like SQL databases
- This module creates metadata vertices in the graph to track VA configuration
- Authentication is typically handled at the cluster level via IAM or database authentication

## Usage

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your actual values:
   - Neptune cluster endpoint and credentials
   - VPC and subnet IDs
   - Guardium server details
   - VA configuration preferences

3. Initialize Terraform:
```bash
terraform init
```

4. Review the planned changes:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

## Configuration Details

### Neptune Connection
- **Endpoint**: The Neptune cluster endpoint (e.g., `my-cluster.cluster-xxxxx.region.neptune.amazonaws.com`)
- **Port**: Default is 8182 (Neptune's default port)
- **Authentication**: Uses database authentication (username/password)

### Lambda Function
The module deploys a Lambda function that:
- Connects to Neptune using the Gremlin Python driver
- Creates VA configuration metadata as graph vertices
- Stores configuration in AWS Secrets Manager
- Runs in your VPC for secure access to Neptune

### Network Requirements
- Lambda must be deployed in subnets with access to Neptune
- Security groups must allow Lambda to connect to Neptune on port 8182
- VPC endpoint for Secrets Manager is automatically created

## Outputs

After successful deployment, you'll see:
- Neptune cluster connection details
- Lambda function information
- Secrets Manager secret ARN
- Guardium data source registration status
- VA schedule configuration

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## Important Notes

1. **Security**: 
   - Store sensitive values (passwords, secrets) securely
   - Use AWS Secrets Manager or HashiCorp Vault for production
   - Ensure proper IAM roles and security groups

2. **Neptune Access**:
   - Lambda needs network access to Neptune cluster
   - Consider using VPC endpoints for better security
   - Neptune supports IAM database authentication (recommended for production)

3. **Graph Database**:
   - Neptune doesn't have traditional SQL users
   - VA configuration is stored as graph metadata
   - Ensure your Neptune cluster has audit logging enabled for comprehensive monitoring

4. **Cost Considerations**:
   - Lambda function execution costs
   - Secrets Manager storage costs
   - VPC endpoint costs
   - Neptune cluster costs

## Troubleshooting

### Lambda Connection Issues
- Verify security groups allow Lambda to Neptune communication
- Check subnet routing and NAT gateway configuration
- Ensure Neptune cluster is in the same VPC or has proper peering

### Authentication Failures
- Verify Neptune credentials are correct
- Check if IAM database authentication is enabled
- Ensure the user has appropriate permissions

### VA Configuration Issues
- Check Lambda CloudWatch logs for detailed error messages
- Verify Guardium server is accessible from Lambda
- Ensure OAuth client credentials are valid

---

## 🔧 Common Configuration Issues

### Issue 1: "Value not in constant list" Error

**Error from Guardium**:
```json
{
  "ErrorCode": "23",
  "ErrorMessage": "create_datasource: Wrong value: 'awsSecretsManagerConfigName' must be one of possible values. Value not in constant list."
}
```

**Cause**: The `aws_secrets_manager_config_name` doesn't exist in Guardium Data Protection.

**Solution**:
1. Log into Guardium UI
2. Go to: **Setup** → **Tools and Views** → **Secrets Management**
3. Verify your AWS Secrets Manager configuration exists
4. Copy the exact name (case-sensitive)
5. Update `terraform.tfvars`:

```hcl
# ❌ WRONG - Invalid or encrypted value
aws_secrets_manager_config_name = "xGRCCZy9DZPH+vFo6Wk8Apc1KpnCqM5sRCd23yrk"

# ✅ CORRECT - Actual config name from Guardium
aws_secrets_manager_config_name = "aws-prod"
```

**⚠️ Important**: Create the AWS Secrets Manager configuration in Guardium **BEFORE** running Terraform.

---

### Issue 2: "Cannot set external password type" Error

**Error from Guardium**:
```json
{
  "ErrorCode": "113",
  "ErrorMessage": "create_datasource: Cannot set external password type. The datasource is not using external password."
}
```

**Cause**: You're using AWS Secrets Manager but `use_external_password = false`.

**Solution**: When using AWS Secrets Manager, you **MUST** set `use_external_password = true`.

```hcl
# ✅ CORRECT Configuration
use_external_password           = true  # MUST be true when using AWS Secrets Manager
aws_secrets_manager_config_name = "aws-prod"
region                          = "us-west-2"
secret_name                     = "guardium/neptune/credentials"
```

---

### Issue 3: VPC Endpoint Already Exists

**Error**:
```
Error: creating EC2 VPC Endpoint: private-dns-enabled cannot be set because there is
already a conflicting DNS domain for secretsmanager.us-west-2.amazonaws.com in the VPC
```

**Solution**: Import the existing VPC endpoint.

```bash
# Find existing VPC endpoint
aws ec2 describe-vpc-endpoints \
  --region us-west-2 \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
            "Name=service-name,Values=com.amazonaws.us-west-2.secretsmanager" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text

# Import it
terraform import module.neptune_va_config.aws_vpc_endpoint.secretsmanager vpce-xxxxx
```

---

### Issue 4: Secret Scheduled for Deletion

**Error**:
```
Error: You can't create this secret because a secret with this name is already scheduled for deletion.
```

**Solution**: Restore and import the secret.

```bash
# Find the secret
aws secretsmanager list-secrets \
  --region us-west-2 \
  --include-planned-deletion \
  --filters Key=name,Values=guardium-neptune-va-password

# Restore it
aws secretsmanager restore-secret \
  --secret-id arn:aws:secretsmanager:us-west-2:123456789:secret:guardium-neptune-va-password-ABC123 \
  --region us-west-2

# Import it
terraform import module.neptune_va_config.aws_secretsmanager_secret.neptune_credentials \
  arn:aws:secretsmanager:us-west-2:123456789:secret:guardium-neptune-va-password-ABC123
```

---

## 📋 Pre-Deployment Checklist

Before running `terraform apply`, verify:

### ✅ AWS Resources
- [ ] Neptune cluster is running and accessible
- [ ] VPC and subnets are configured
- [ ] Security groups allow Lambda → Neptune (port 8182)
- [ ] IAM permissions for Lambda, Secrets Manager, VPC

### ✅ Guardium Configuration
- [ ] Guardium server is accessible
- [ ] OAuth credentials are valid
- [ ] **AWS Secrets Manager configuration exists in Guardium UI**
- [ ] Configuration name is correct (case-sensitive)
- [ ] `use_external_password = true` is set in terraform.tfvars

### ✅ Network Connectivity
- [ ] Lambda can reach Neptune cluster
- [ ] Lambda can reach Guardium server
- [ ] VPC has internet access (for AWS API calls)

---

## 🐛 Debug Mode

Enable detailed logging:

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run Terraform
terraform apply -auto-approve

# Search for errors
grep -i "error" terraform-debug.log
grep "register data source response" terraform-debug.log
```

Check Lambda logs:
```bash
# Get Lambda function name from Terraform output
LAMBDA_NAME=$(terraform output -raw lambda_function_name)

# View recent logs
aws logs tail /aws/lambda/$LAMBDA_NAME --follow
```

---

## 📞 Getting Help

When reporting issues, provide:

1. **Versions**:
   ```bash
   terraform version
   aws --version
   ```

2. **Error messages**: Full output from Terraform

3. **Configuration**: Sanitized terraform.tfvars (remove passwords)

4. **Network tests**:
   ```bash
   # Test Neptune connectivity
   telnet your-neptune-cluster.amazonaws.com 8182
   
   # Test Guardium connectivity
   curl -k https://your-guardium-server:8443/api/v2/health
   ```

5. **Lambda logs**: From CloudWatch Logs

For detailed troubleshooting, see the [module README](../../modules/aws-neptune/README.md#terraform-import-guide--troubleshooting).

---

## Support

For issues or questions:
- Check the module README: `../../modules/aws-neptune/README.md`
- Review Lambda function logs in CloudWatch
- Consult Guardium documentation for VA configuration

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0