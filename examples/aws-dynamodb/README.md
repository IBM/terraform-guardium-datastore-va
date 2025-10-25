# AWS DynamoDB with Vulnerability Assessment

This example demonstrates how to configure vulnerability assessment for AWS DynamoDB using Guardium Data Protection. It sets up the necessary IAM roles and policies for Guardium to perform security assessments on your DynamoDB tables and connects the datasource to Guardium for ongoing vulnerability monitoring.

## Architecture

```
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│                   │     │                   │     │                   │
│  AWS DynamoDB     │     │  IAM Role/Policy  │     │  Guardium Data    │
│  Service          │◄────┤  for VA           │◄────┤  Protection       │
│                   │     │                   │     │                   │
└───────────────────┘     └───────────────────┘     └───────────────────┘
                                                           │
                                                           │ Performs
                                                           ▼
                                                    ┌───────────────────┐
                                                    │                   │
                                                    │  Vulnerability    │
                                                    │  Assessment       │
                                                    │                   │
                                                    └───────────────────┘
                                                           │
                                                           │ Generates
                                                           ▼
                                                    ┌───────────────────┐
                                                    │                   │
                                                    │  Assessment       │
                                                    │  Reports          │
                                                    │                   │
                                                    └───────────────────┘
```

## Data Flow

1. Guardium Data Protection uses the configured IAM role to access DynamoDB
2. Guardium performs vulnerability assessments according to the configured schedule
3. Assessment results are stored in Guardium and notifications are sent based on configuration
4. Security teams can review findings and take remediation actions

## Prerequisites

- AWS account with DynamoDB tables
- Guardium Data Protection instance
- AWS credentials with permissions to create IAM roles and policies
- Terraform >= 1.0.0
- AWS provider >= 4.0.0
- Guardium provider >= 1.0.0

### AWS Authentication Setup

Before running Terraform, ensure you have valid AWS credentials configured:

1. Validate your AWS authentication by running:
   ```bash
   aws sts get-caller-identity
   ```
   This should return your AWS account ID, user ID, and ARN.

2. If needed, configure your AWS credentials by editing `~/.aws/credentials`:
   ```
   [default]
   aws_access_key_id = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   ```

## Usage

### 1. Configure the variables

Create a `terraform.tfvars` file with your specific configuration:

```hcl
# AWS Configuration
aws_region  = "us-east-1"
aws_profile = "default"

# Guardium Data Protection Connection
gdp_server = "guardium.example.com"
gdp_port   = 8443
guardium_username = "apiuser"
guardium_password = "password"
client_id = "client1"
client_secret = "client_secret123"
gdp_ssh_username = "root"
gdp_ssh_privatekeypath = "~/.ssh/id_rsa"


# DynamoDB uses AWS Secrets Manager for authentication
# These are required for DynamoDB datasource registration
# DynamoDB authentication is handled through AWS Secrets Manager
# No username/password required for DynamoDB
aws_secrets_manager_name = "YOURaccount"  # Name of your AWS Secrets Manager configuration in Guardium
aws_secrets_manager_region = "us-east-1"  # Region where your AWS Secrets Manager secret is stored
aws_secrets_manager_secret = "dynamodb-credentials"  # Name of the secret in AWS Secrets Manager


# Vulnerability Assessment Configuration
enable_vulnerability_assessment = true
assessment_schedule             = "WEEKLY"
assessment_day                  = "Monday"
assessment_time                 = "02:00"  # 2 AM

# Notification Configuration
enable_notifications  = true
notification_emails   = ["security@example.com", "dba@example.com"]
notification_severity = "HIGH"

# Debug Configuration
debug_mode = true  # Enable to see API responses for troubleshooting

# Tags
tags = {
  Environment = "Production"
  Owner       = "Security Team"
  Project     = "Database Security"
}
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the plan

```bash
terraform plan
```

### 4. Apply the configuration

```bash
terraform apply
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region where DynamoDB is deployed | `string` | `"us-east-1"` | no |
| aws_profile | AWS profile to use for authentication | `string` | `"default"` | no |
| gdp_server | Hostname or IP address of the Guardium Data Protection server | `string` | n/a | yes |
| gdp_port | Port for Guardium Data Protection API connection | `number` | `8443` | no |
| guardium_username | Username for Guardium API authentication | `string` | n/a | yes |
| guardium_password | Password for Guardium API authentication | `string` | n/a | yes |
| client_id | The client ID used to create the GDP register_oauth_client client_secret | `string` | `"client1"` | no |
| client_secret | The client secret output from grdapi register_oauth_client | `string` | n/a | yes |
| gdp_ssh_username | The SSH user for logging in to Guardium | `string` | `"root"` | no |
| gdp_ssh_privatekeypath | The path to the SSH private key for logging in to Guardium | `string` | n/a | yes |
| aws_secrets_manager_name | Name of the AWS Secrets Manager configuration in Guardium | `string` | n/a | yes |
| aws_secrets_manager_region | AWS region where the Secrets Manager secret is stored | `string` | n/a | yes |
| dynamodb_datasource_name | Name to register the DynamoDB datasource in Guardium | `string` | `"aws-dynamodb-va-example"` | no |
| dynamodb_description | Description for the DynamoDB datasource in Guardium | `string` | `"AWS DynamoDB with Vulnerability Assessment"` | no |
| enable_vulnerability_assessment | Whether to enable vulnerability assessment for DynamoDB | `bool` | `true` | no |
| assessment_schedule | Schedule for vulnerability assessments (DAILY, WEEKLY, MONTHLY) | `string` | `"WEEKLY"` | no |
| assessment_day | Day for vulnerability assessments (e.g., Monday, Tuesday) | `string` | `"Monday"` | no |
| assessment_time | Time for vulnerability assessments in 24-hour format (HH:MM) | `string` | `"00:00"` | no |
| enable_notifications | Whether to enable notifications for vulnerability assessment results | `bool` | `true` | no |
| notification_emails | Email addresses to receive vulnerability assessment notifications | `list(string)` | `[]` | no |
| notification_severity | Minimum severity level for notifications (LOW, MEDIUM, HIGH, CRITICAL) | `string` | `"HIGH"` | no |
| tags | Tags to apply to resources created by this module | `map(string)` | `{}` | no |
| debug_mode | Enable debug mode to print API responses for troubleshooting | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| va_iam_role_arn | ARN of the IAM role used for vulnerability assessment |
| va_iam_policy_arn | ARN of the IAM policy for vulnerability assessment |
| datasource_name | Name of the registered datasource in Guardium |
| datasource_type | Type of the registered datasource in Guardium |
| datasource_hostname | Hostname of the registered datasource in Guardium |
| va_enabled | Whether vulnerability assessment is enabled |
| assessment_schedule | Schedule for vulnerability assessments |
| assessment_day | Day for vulnerability assessments |
| assessment_time | Time for vulnerability assessments |
| notifications_enabled | Whether notifications are enabled |
| notification_emails | Email addresses for notifications |
| notification_severity | Minimum severity level for notifications |
| debug_mode_enabled | Whether debug mode is enabled for API responses |

## Security Considerations

- Store sensitive variables like `guardium_password` and `connection_password` in a secure location such as AWS Secrets Manager or HashiCorp Vault
- Use environment variables or a `.tfvars` file that is excluded from version control
- Consider using AWS IAM roles with temporary credentials instead of long-lived access keys
- Regularly rotate credentials used for the DynamoDB connection
- Implement least privilege for the IAM policy, restricting access to only the necessary DynamoDB tables
- Ensure your AWS Secrets Manager secret contains the necessary AWS credentials with appropriate permissions

## AWS Secrets Manager Configuration

For DynamoDB datasources, Guardium requires AWS Secrets Manager configuration. You need to:

1. **Register AWS Authentication Configuration in Guardium UI**:
   - Navigate to Setup >> Tools >> AWS Authentication Configuration
   - Create a new configuration with a name (this will be your `aws_secrets_manager_name`)
   - Enter your AWS credentials (Access Key ID and Secret Access Key)
   - Save the configuration

2. Create an AWS Secrets Manager secret containing your AWS credentials:
   ```bash
   aws secretsmanager create-secret \
     --name dynamodb-credentials \
     --description "AWS credentials for Guardium DynamoDB VA" \
     --secret-string '{"accessKeyId":"YOUR_ACCESS_KEY_ID","secretAccessKey":"YOUR_SECRET_ACCESS_KEY"}'
   ```

3. Ensure the secret is in the format:
   ```json
   {
     "accessKeyId": "YOUR_ACCESS_KEY_ID",
     "secretAccessKey": "YOUR_SECRET_ACCESS_KEY"
   }
   ```

4. Provide the configuration details in your terraform.tfvars file:
   ```hcl
   aws_secrets_manager_name = "<yourprofile>"  # Name you used in Guardium UI
   aws_secrets_manager_region = "us-east-1"
   aws_secrets_manager_secret = "dynamodb-credentials"  # Name of your AWS secret
   ```

5. The IAM role used by Guardium must have permission to read this secret.

## Additional Notes

- This example focuses solely on vulnerability assessment and does not include audit logging
- For audit logging of DynamoDB, see the `examples/dynamodb-monitoring` example which uses CloudTrail, CloudWatch, and Universal Connector
- Vulnerability assessments check for security misconfigurations, weak access controls, and other security issues
- Assessment results can be viewed in the Guardium Data Protection console
- DynamoDB authentication is handled entirely through AWS Secrets Manager - no username/password is required.
- The `aws_secrets_manager_name` variable refers to the AWS Authentication Configuration name you created in the Guardium UI (Setup >> Tools >> AWS Authentication Configuration).
- **IMPORTANT**: The AWS Authentication Configuration name in Guardium UI must match exactly what you specify in `aws_secrets_manager_name`.
- The `aws_secrets_manager_region` and `aws_secrets_manager_secret` variables specify the AWS region and secret name containing the AWS credentials.
- The `debug_mode` variable can be enabled to print detailed API requests and responses for troubleshooting. This is useful when diagnosing issues with the Guardium API integration. Keep this disabled in production environments to avoid exposing sensitive information in logs.
- Note that for DynamoDB datasources, the vulnerability assessment configuration must be done manually through the Guardium UI after the datasource is registered. The Terraform module will register the datasource but cannot configure the vulnerability assessment for DynamoDB datasources due to API limitations.
