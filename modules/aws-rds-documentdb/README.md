<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS DocumentDB Vulnerability Assessment Configuration Module

This Terraform module configures an AWS RDS DocumentDB cluster for Guardium Vulnerability Assessment (VA) and connects it to Guardium Data Protection (GDP). It creates the necessary users and permissions required for Guardium to perform security assessments and entitlement reports.

## Architecture

The module deploys the following components:
1. A Lambda function in your VPC that configures the DocumentDB cluster
2. AWS Secrets Manager to securely store database credentials
3. IAM roles and policies for the Lambda function
4. VPC endpoints for secure communication
5. Connection to Guardium Data Protection for vulnerability assessment

## Features

- Creates a `sqlguard` user with the necessary permissions for vulnerability assessment
- Grants the required roles for Guardium VA to work properly:
  - `read` on admin database
  - `readAnyDatabase` for cluster-wide read access
  - `clusterMonitor` for monitoring capabilities
- Configures the database for Guardium Vulnerability Assessment
- Deploys a Lambda function to execute the configuration in the VPC where the DocumentDB cluster resides
- Connects the database to Guardium Data Protection for ongoing security monitoring
- Configures scheduled vulnerability assessments and notifications

## Prerequisites

- An existing AWS RDS DocumentDB cluster (version 4.0 or above)
- The user executing the module must have admin privileges on the cluster
- The cluster must be accessible from the Lambda function (in the same VPC or with proper network connectivity)
- The cluster security group must allow connections from Guardium server on port 27017
- VPC and subnet IDs where the Lambda function will be deployed
- Access to a Guardium Data Protection (GDP) instance
- OAuth client credentials for the Guardium API

## Usage

### Basic Usage

```hcl
module "aws-rds-documentdb" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-documentdb"

  name_prefix = "myproject"
  
  # Database connection details
  db_host     = "your-documentdb-cluster.cluster-xxxxxx.us-east-1.docdb.amazonaws.com"
  db_port     = 27017
  db_username = "admin"
  db_password = "your-password"
  
  # VA user credentials
  sqlguard_username = "sqlguard"
  sqlguard_password = "SecurePassword123!"
  
  # Network configuration
  vpc_id                = "vpc-xxxxxx"
  subnet_ids            = ["subnet-xxxxxx", "subnet-xxxxxx"]
  db_security_group_id  = "sg-xxxxxx"
  aws_region            = "us-east-1"
  
  tags = {
    Environment = "production"
    Purpose     = "guardium-va"
  }
}
```

### Custom sqlguard User

```hcl
module "aws-rds-documentdb" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-documentdb"

  name_prefix = "myproject"
  
  # Database connection details
  db_host          = "your-documentdb-cluster.cluster-xxxxxx.us-west-2.docdb.amazonaws.com"
  db_port          = 27017
  db_username      = "admin"
  db_password      = "your-password"
  
  # Custom sqlguard credentials
  sqlguard_username = "custom_guard"
  sqlguard_password = "CustomPassword123!"
  
  # Network configuration
  vpc_id                = "vpc-xxxxxxxx"
  subnet_ids            = ["subnet-xxxxxxxx"]
  db_security_group_id  = "sg-xxxxxxxx"
  aws_region            = "us-west-2"
}
```

## Required Inputs

| Name | Description | Type |
|------|-------------|------|
| name_prefix | Prefix to use for resource names | `string` |
| db_host | Hostname or IP address of the DocumentDB cluster | `string` |
| db_username | Username for the DocumentDB cluster (must have admin privileges) | `string` |
| db_password | Password for the DocumentDB cluster | `string` |
| sqlguard_password | Password for the sqlguard user | `string` |
| vpc_id | ID of the VPC where the Lambda function will be deployed | `string` |
| subnet_ids | List of subnet IDs where the Lambda function will be deployed | `list(string)` |
| db_security_group_id | Security group ID of the DocumentDB cluster | `string` |
| aws_region | AWS region where resources will be created | `string` |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| db_port | Port for the DocumentDB cluster | `number` | `27017` |
| sqlguard_username | Username for the Guardium user | `string` | `"sqlguard"` |
| tags | Tags to apply to all resources | `map(string)` | `{ Purpose = "guardium-va-config", Owner = "your-email@example.com" }` |
| datasource_name | A unique name for the datasource on the Guardium system | `string` | `"rds-documentdb-va"` |
| datasource_description | Description of the datasource | `string` | `"DocumentDB data source onboarded via Terraform"` |
| application | Application type for the datasource | `string` | `"Security Assessment"` |
| severity_level | Severity classification for the datasource (LOW, NONE, MED, HIGH) | `string` | `"MED"` |
| enable_vulnerability_assessment | Whether to enable vulnerability assessment for the data source | `bool` | `true` |
| assessment_schedule | Schedule for vulnerability assessments (e.g., daily, weekly, monthly) | `string` | `"weekly"` |
| assessment_day | Day to run the assessment (e.g., Monday, 1) | `string` | `"Monday"` |
| assessment_time | Time to run the assessment in 24-hour format (e.g., 02:00) | `string` | `"02:00"` |
| enable_notifications | Whether to enable notifications for assessment results | `bool` | `true` |
| notification_emails | List of email addresses to notify about assessment results | `list(string)` | `[]` |
| notification_severity | Minimum severity level for notifications (HIGH, MED, LOW, NONE) | `string` | `"HIGH"` |
| use_ssl | Enable to use SSL authentication | `bool` | `true` |

For a complete list of all input variables, please refer to the [variables.tf](./variables.tf) file.

## Outputs

| Name | Description |
|------|-------------|
| sqlguard_username | Username for the Guardium user (sqlguard) |
| sqlguard_password | Password for the sqlguard user (sensitive) |

## Implementation Details

The module performs the following actions:

1. **Secrets Management**:
   - Creates an AWS Secrets Manager secret to store database credentials securely
   - Configures a VPC endpoint for Secrets Manager to allow secure access from the Lambda function

2. **Lambda Function Deployment**:
   - Creates an IAM role and policy for the Lambda function
   - Deploys a Lambda function in the specified VPC and subnets
   - Configures security groups for the Lambda function

3. **Database Configuration**:
   - The Lambda function connects to the DocumentDB cluster using the provided credentials with SSL
   - Downloads the RDS CA bundle for SSL certificate verification
   - Creates or updates the `sqlguard` user with the specified password
   - Grants the necessary roles for Guardium VA:
     - `read` on admin database
     - `readAnyDatabase` for cluster-wide read access
     - `clusterMonitor` for monitoring capabilities
   - Verifies the user can authenticate successfully

4. **Guardium Data Protection Integration**:
   - Registers the database as a data source in Guardium Data Protection
   - Configures vulnerability assessment schedules
   - Sets up notification preferences for assessment results

## Network Configuration for Guardium Access

**Important**: This module configures the database user (`sqlguard`) but does **not** automatically configure network access from Guardium to your DocumentDB cluster. You must manually add a security group rule to allow Guardium's IP address.

### Why This Is Required

The module creates:
- Lambda function → DocumentDB connectivity (automatic)
- Database user `sqlguard` with proper permissions (automatic)
- Guardium server → DocumentDB connectivity (manual configuration required)

Guardium needs direct network access to perform vulnerability assessments. Without this, you'll see connection timeout errors.

### Quick Setup

1. **Get Guardium's public IP** (run on Guardium server):
   ```bash
   curl ifconfig.me
   ```

2. **Find your DocumentDB security group**:
   ```bash
   aws docdb describe-db-clusters \
     --db-cluster-identifier <your-cluster-id> \
     --region <your-region> \
     --query 'DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId' \
     --output text
   ```

3. **Add security group rule**:
   ```bash
   aws ec2 authorize-security-group-ingress \
     --group-id sg-xxxxxxxxxxxxxxxxx \
     --protocol tcp \
     --port 27017 \
     --cidr xxx.xxx.xxx.xxx/32 \
     --region <your-region> \
     --description "Guardium VA access"
   ```

4. **Verify the rule**:
   ```bash
   aws ec2 describe-security-groups \
     --group-ids sg-xxxxxxxxxxxxxxxxx \
     --region <your-region> \
     --query 'SecurityGroups[0].IpPermissions[?ToPort==`27017`]' \
     --output table
   ```

5. **Test from Guardium** (requires mongo shell):
   ```bash
   mongo --ssl --host your-documentdb-cluster.cluster-xxxxxx.region.docdb.amazonaws.com:27017 \
     --sslCAFile rds-combined-ca-bundle.pem \
     --username sqlguard \
     --password <password>
   ```

For detailed instructions and troubleshooting, see the [example README](../../examples/aws-rds-documentdb/README.md#configuring-network-access-for-guardium).

## Security Considerations

- All database credentials are stored securely in AWS Secrets Manager
- The Lambda function runs in your VPC with minimal permissions
- Network access is restricted using security groups
- SSL/TLS is enabled by default for DocumentDB connections
- The RDS CA bundle is downloaded and used for certificate verification
- Sensitive variables are marked as such to prevent exposure in logs

## DocumentDB-Specific Notes

- DocumentDB is MongoDB-compatible but not identical to MongoDB
- SSL/TLS is required for DocumentDB connections
- The module uses the `pymongo` library for Python to connect to DocumentDB
- DocumentDB uses a replica set architecture; the connection string includes `replicaSet=rs0`
- Read preference is set to `secondaryPreferred` for better performance
- `retryWrites=false` is set as DocumentDB doesn't support retryable writes

## Troubleshooting

Common issues and their solutions:

1. **Lambda function fails to connect to the cluster**:
   - Ensure the security groups allow traffic from the Lambda function to the cluster
   - Verify that the cluster is in the same VPC or accessible via VPC peering
   - Check that the provided database credentials are correct
   - Verify SSL is properly configured
   - Check the logs in the created CloudWatch log group

2. **SSL Certificate Errors**:
   - The Lambda function automatically downloads the RDS CA bundle
   - Ensure the Lambda has internet access or a VPC endpoint for HTTPS
   - Verify the CA bundle download is successful in CloudWatch logs

3. **Permission errors when configuring the database**:
   - Ensure the database user has admin privileges on the cluster
   - Check that the cluster is not in a read-only mode

4. **Guardium connection issues**:
   - Verify that the Guardium server can reach the DocumentDB cluster on port 27017
   - Check that the security group allows inbound traffic from Guardium's IP
   - Verify SSL certificates are properly configured on Guardium
   - Test connection using mongo shell from Guardium server

5. **User creation fails**:
   - Verify the admin user has sufficient privileges
   - Check CloudWatch logs for detailed error messages
   - Ensure the cluster is in available state

## Additional Resources

- [AWS DocumentDB Documentation](https://docs.aws.amazon.com/documentdb/)
- [DocumentDB Security Best Practices](https://docs.aws.amazon.com/documentdb/latest/developerguide/security-best-practices.html)
- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [PyMongo Documentation](https://pymongo.readthedocs.io/)