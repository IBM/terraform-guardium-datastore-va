# AWS RDS PostgreSQL with Vulnerability Assessment

This example demonstrates how to configure AWS RDS PostgreSQL with Guardium Vulnerability Assessment (VA) capabilities. It sets up the necessary components to perform security assessments on your PostgreSQL database and receive notifications about potential vulnerabilities.

## Overview

This example:

1. Configures a PostgreSQL database for Vulnerability Assessment by creating a dedicated `sqlguard` user with appropriate permissions
2. Connects the PostgreSQL database to Guardium Data Protection (GDP) for vulnerability scanning
3. Sets up scheduled vulnerability assessments and configures notification preferences

## Architecture

```
┌─────────────────┐          ┌─────────────────┐
│                 │          │                 │
│  AWS RDS        │◄────────►│  AWS Lambda     │
│  PostgreSQL     │          │  (VA Config)    │
│                 │          │                 │
└────────┬────────┘          └────────┬────────┘
         │                            │
         │                            │
         │                            │
         ▼                            ▼
┌─────────────────┐          ┌─────────────────┐
│                 │          │                 │
│  Guardium Data  │◄────────►│  Vulnerability  │
│  Protection     │          │  Assessment     │
│                 │          │                 │
└─────────────────┘          └─────────────────┘
```

## Prerequisites

Before using this example, you need:

1. **AWS Resources**:
   - An existing AWS RDS PostgreSQL database
   - VPC and subnet information where the database is deployed
   - Appropriate IAM permissions to create Lambda functions and Secrets Manager resources

2. **Guardium Data Protection**:
   - Access to a Guardium Data Protection instance
   - Admin credentials for the GDP instance
   - OAuth client credentials (generated using `grdapi register_oauth_client`)
   - SSH access to the GDP instance (for file operations)

3. **Terraform Configuration**:
   - Terraform installed (version >= 1.0.0)
   - AWS CLI configured
   - Terraform provider for Guardium Data Protection configured

## Usage

1. **Prepare Configuration**:

   Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your specific values:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```

## Configuration Options

### Database Connection

| Variable | Description | Default |
|----------|-------------|---------|
| `db_host` | PostgreSQL database hostname or endpoint | - |
| `db_port` | PostgreSQL database port | `5432` |
| `db_name` | Database name to connect to | - |
| `db_username` | Master username for database access | `"guardium_admin"` |
| `db_password` | Master password for database access | - |

### Network Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_id` | VPC ID where the database is located | - |
| `subnet_ids` | List of subnet IDs for Lambda deployment | - |

### Vulnerability Assessment User

| Variable | Description | Default |
|----------|-------------|---------|
| `sqlguard_username` | Username for the VA user | `"sqlguard"` |
| `sqlguard_password` | Password for the VA user | - |

### Guardium Connection

| Variable | Description | Default |
|----------|-------------|---------|
| `gdp_server` | Guardium server hostname or IP | - |
| `gdp_port` | Guardium server port | `"8443"` |
| `gdp_username` | Guardium admin username | - |
| `gdp_password` | Guardium admin password | - |
| `client_id` | OAuth client ID | `"client1"` |
| `client_secret` | OAuth client secret | - |

### Assessment Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_vulnerability_assessment` | Whether to enable VA | `true` |
| `assessment_schedule` | Schedule frequency | `"weekly"` |
| `assessment_day` | Day to run assessment | `"Monday"` |
| `assessment_time` | Time to run assessment | `"02:00"` |

### Notification Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_notifications` | Whether to enable notifications | `true` |
| `notification_emails` | Email addresses for notifications | `[]` |
| `notification_severity` | Minimum severity for notifications | `"HIGH"` |

## How It Works

1. **VA Configuration**:
   - Creates a Lambda function that connects to your PostgreSQL database
   - Creates a dedicated `sqlguard` user with appropriate permissions
   - Sets up the necessary database configuration for vulnerability assessment

2. **GDP Connection**:
   - Registers the PostgreSQL database as a data source in Guardium
   - Configures vulnerability assessment scheduling
   - Sets up notification preferences

3. **Assessment Execution**:
   - Guardium will perform vulnerability assessments according to the schedule
   - Assessment results will be available in the Guardium console
   - Notifications will be sent based on your configuration

## Security Considerations

- The `sqlguard` user is created with minimal necessary permissions
- All sensitive variables are marked as sensitive in Terraform
- Lambda functions run in your VPC with restricted security groups
- Consider using AWS Secrets Manager for credential management in production

## Troubleshooting

### Common Issues

1. **Connection Failures**:
   - Verify network connectivity between Lambda and RDS
   - Check security group rules allow traffic on port 5432
   - Verify database credentials are correct

2. **Permission Issues**:
   - Ensure the master database user has sufficient privileges
   - Check that the Lambda execution role has appropriate permissions

3. **Guardium Connection Issues**:
   - Verify Guardium credentials and OAuth settings
   - Check network connectivity to the Guardium server
   - Ensure the Guardium provider is properly configured

### Logs and Debugging

- Check CloudWatch Logs for Lambda function execution logs
- Review Guardium logs for connection and assessment issues
- Use AWS CloudTrail for API call troubleshooting

## Cleanup

To remove all resources created by this example:

```bash
terraform destroy
```

Note: This will not remove any existing RDS PostgreSQL instances that were referenced but not created by this configuration.
