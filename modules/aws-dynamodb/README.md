# AWS DynamoDB Vulnerability Assessment Configuration Module

This Terraform module configures the necessary AWS IAM resources for Guardium Data Protection to perform vulnerability assessment on AWS DynamoDB tables. It creates an IAM role and policy with the required permissions for Guardium to access DynamoDB metadata and configuration.

## Features

- Creates an IAM role that Guardium can assume to access DynamoDB resources
- Creates an IAM policy with the necessary permissions for vulnerability assessment
- Attaches the policy to the role
- Configures connection credentials for DynamoDB access

## Usage

```hcl
module "dynamodb_va" {
  source = "path/to/modules/datastore-va-config/aws-dynamodb"

  # IAM Configuration
  iam_role_name        = "guardium-dynamodb-va-role"
  iam_policy_name      = "guardium-dynamodb-va-policy"
  iam_role_description = "IAM role for Guardium vulnerability assessment of DynamoDB"
  
  # Connection Configuration
  connection_username = var.aws_access_key_id
  connection_password = var.aws_secret_access_key
  
  # Tags
  tags = {
    Environment = "Production"
    Owner       = "Security Team"
  }
}
```

## IAM Permissions

The module creates an IAM policy with the following permissions:

- List and describe DynamoDB resources
- Read table metadata and configuration
- Read backup and restore configuration
- Read global tables configuration
- Read table streams
- Read table metrics via CloudWatch
- Read related IAM policies
- Read KMS keys used by DynamoDB
- Read VPC endpoints for DynamoDB

These permissions are read-only and do not allow modification of DynamoDB resources.

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| iam_role_name | Name of the IAM role for Guardium vulnerability assessment | `string` | `"guardium-dynamodb-va-role"` | no |
| iam_policy_name | Name of the IAM policy for Guardium vulnerability assessment | `string` | `"guardium-dynamodb-va-policy"` | no |
| iam_role_description | Description of the IAM role for Guardium vulnerability assessment | `string` | `"IAM role for Guardium vulnerability assessment of DynamoDB"` | no |
| connection_username | Username for DynamoDB connection (AWS Access Key ID) | `string` | n/a | yes |
| connection_password | Password for DynamoDB connection (AWS Secret Access Key) | `string` | n/a | yes |
| tags | Tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| iam_role_arn | ARN of the IAM role for Guardium vulnerability assessment |
| iam_role_name | Name of the IAM role for Guardium vulnerability assessment |
| iam_role_id | ID of the IAM role for Guardium vulnerability assessment |
| iam_policy_arn | ARN of the IAM policy for Guardium vulnerability assessment |
| iam_policy_name | Name of the IAM policy for Guardium vulnerability assessment |
| iam_policy_id | ID of the IAM policy for Guardium vulnerability assessment |
| connection_username | Username for DynamoDB connection (AWS Access Key ID) |

## Security Considerations

- The IAM role uses a trust policy that allows any AWS principal (`"AWS": "*"`) to assume the role. This is because Guardium will establish the trust relationship externally. In a production environment, you should consider restricting this to specific Guardium service accounts.
- Store sensitive variables like `connection_password` in a secure location such as AWS Secrets Manager or HashiCorp Vault.
- Consider using AWS IAM roles with temporary credentials instead of long-lived access keys.
- Regularly rotate credentials used for the DynamoDB connection.

## Integration with Guardium Data Protection

This module is designed to be used with the `connect-datasource-to-gdp` module to register the DynamoDB datasource with Guardium Data Protection and enable vulnerability assessment. See the `examples/aws-dynamodb-with-va` directory for a complete example.

## Requirements

- Terraform >= 1.0.0
- AWS Provider >= 4.0.0