<!--
Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0
-->

# AWS RDS DocumentDB with Guardium Vulnerability Assessment - Example

This example demonstrates how to configure an AWS RDS DocumentDB cluster for Guardium Vulnerability Assessment (VA) and connect it to Guardium Data Protection (GDP).

## Overview

This example will:
1. (Optional) Set up VPC peering if Guardium is in a different VPC
2. Deploy a Lambda function to configure the DocumentDB cluster with a `sqlguard` user
3. Grant necessary permissions for Guardium VA
4. Register the DocumentDB cluster as a data source in Guardium Data Protection
5. Configure scheduled vulnerability assessments
6. Set up notifications for assessment results

## Architecture

### Same VPC Deployment
```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC                                 │
│                                                                   │
│  ┌──────────────────┐         ┌─────────────────────────────┐  │
│  │  Lambda Function │────────▶│  DocumentDB Cluster         │  │
│  │  (VA Config)     │         │  - Creates sqlguard user    │  │
│  └──────────────────┘         │  - Grants permissions       │  │
│           │                    └─────────────────────────────┘  │
│           │                                 │                    │
│           ▼                                 │                    │
│  ┌──────────────────┐                      │                    │
│  │  Secrets Manager │                      │                    │
│  │  (Credentials)   │                      │                    │
│  └──────────────────┘                      │                    │
│                                             │                    │
└─────────────────────────────────────────────┼────────────────────┘
                                              │
                                              │ Port 27017
                                              │ (SSL/TLS)
                                              ▼
                                    ┌──────────────────┐
                                    │  Guardium Data   │
                                    │  Protection      │
                                    │  - VA Scans      │
                                    │  - Monitoring    │
                                    └──────────────────┘
```

### Cross-VPC Deployment (with VPC Peering)
```
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│      Guardium VPC               │    │      DocumentDB VPC              │
│                                 │    │                                  │
│  ┌──────────────────┐           │    │  ┌──────────────────┐           │
│  │  Guardium Data   │           │    │  │  Lambda Function │           │
│  │  Protection      │           │    │  │  (VA Config)     │           │
│  │  - VA Scans      │◀──────────┼────┼─▶│                  │           │
│  │  - Monitoring    │  Peering  │    │  └────────┬─────────┘           │
│  └──────────────────┘  Connection    │           │                      │
│                                 │    │           ▼                      │
└─────────────────────────────────┘    │  ┌──────────────────┐           │
                                       │  │  Secrets Manager │           │
         Port 27017 (SSL/TLS)          │  └──────────────────┘           │
                 │                     │           │                      │
                 │                     │           ▼                      │
                 │                     │  ┌─────────────────────────┐    │
                 └─────────────────────┼─▶│  DocumentDB Cluster     │    │
                                       │  │  - sqlguard user        │    │
                                       │  └─────────────────────────┘    │
                                       │                                  │
                                       └──────────────────────────────────┘
```

## Prerequisites

### 1. AWS Resources
- An existing AWS RDS DocumentDB cluster (version 4.0 or above)
- VPC and subnets where the Lambda function will be deployed
- Security groups configured for:
  - Lambda to DocumentDB communication
  - Guardium to DocumentDB communication (manual setup required)

### 2. DocumentDB Configuration
- Admin user credentials with privileges to create users and grant roles
- Cluster must be accessible from the Lambda function's VPC/subnets
- **SSL/TLS MUST be enabled on the DocumentDB cluster** (enabled by default, but verify before proceeding)

### 3. Guardium Data Protection

**IMPORTANT: Guardium must be hosted in the same AWS account as DocumentDB** 

- Access to a Guardium Data Protection instance
- Admin credentials for Guardium
- OAuth client credentials (generate using `grdapi register_oauth_client`)

**Supported Deployment Scenarios:**
- Guardium in same VPC as DocumentDB (no VPC peering needed)
- Guardium in different VPC within same AWS account (use VPC peering)
- Guardium in different AWS account (requires manual Transit Gateway/VPN setup)
- Guardium on-premises (requires manual VPN/Direct Connect setup)

**Note:** This module's VPC peering feature only works when Guardium is deployed in the same AWS account. For cross-account or on-premises deployments, you must manually configure network connectivity (Transit Gateway, VPN, or Direct Connect) and set `enable_vpc_peering = false`.

### 4. Network Access
- Lambda function must be able to reach:
  - DocumentDB cluster (port 27017)
  - AWS Secrets Manager (via VPC endpoint or internet)
- Guardium server must be able to reach DocumentDB cluster (port 27017)

### 5. VPC Peering (Optional - Cross-VPC Connectivity)
**Required only if Guardium is in a different VPC from DocumentDB**

- VPC ID where Guardium is deployed
- Both VPCs must be in the same AWS account
- Non-overlapping CIDR blocks between VPCs

**What gets automated:**
- VPC peering connection creation
- Automatic CIDR block discovery from VPC IDs
- Automatic route table discovery in both VPCs
- Route creation in all route tables for bidirectional traffic

**Note**: If Guardium and DocumentDB are in the same VPC, VPC peering is not needed.

## Usage

### Step 1: Clone and Navigate

```bash
git clone <repository-url>
cd examples/aws-rds-documentdb
```

### Step 2: Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# VPC Peering Configuration (Optional - only if Guardium in different VPC)
enable_vpc_peering = false  # Set to true if Guardium is in a different VPC
# guardium_vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Uncomment and set if enable_vpc_peering = true

# DocumentDB Configuration
db_host     = "your-cluster.cluster-xxxxxx.us-east-1.docdb.amazonaws.com"
db_username = "admin"
db_password = "your-secure-password"

# Network Configuration
vpc_id                = "vpc-xxxxxxxxx"
subnet_ids            = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
db_security_group_id  = "sg-xxxxxxxxx"

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "guardium-password"
client_secret = "your-oauth-secret"

# VA User Configuration
sqlguard_username = "sqlguard"
sqlguard_password = "secure-va-password"
```

### Step 3: Generate OAuth Client Secret

On your Guardium server, generate OAuth credentials:

```bash
grdapi register_oauth_client client_id=client1 grant_types=password
```

Copy the generated `client_secret` to your `terraform.tfvars`.

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Review the Plan

```bash
terraform plan
```

### Step 6: Apply the Configuration

```bash
terraform apply
```

Review the planned changes and type `yes` to proceed.

### Step 7: Configure Network Access for Guardium

**Important**: After applying the Terraform configuration, you must manually configure network access from Guardium to DocumentDB.

#### Get Guardium's IP Address

On the Guardium server:
```bash
curl ifconfig.me
```

#### Add Security Group Rule

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <your-documentdb-security-group-id> \
  --protocol tcp \
  --port 27017 \
  --cidr <guardium-ip>/32 \
  --region <your-region> \
  --description "Guardium VA access to DocumentDB"
```

#### Verify Connection from Guardium

On the Guardium server, test the connection:

```bash
# Download the RDS CA bundle
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Test connection using mongo shell
mongo --ssl \
  --host your-cluster.cluster-xxxxxx.region.docdb.amazonaws.com:27017 \
  --sslCAFile global-bundle.pem \
  --username sqlguard \
  --password <sqlguard-password> \
  --authenticationDatabase admin
```

If successful, you should see the MongoDB shell prompt.

## What Gets Created

### AWS Resources

1. **VPC Peering (Optional)**
   - VPC peering connection between Guardium VPC and DocumentDB VPC
   - Automatic route creation in all route tables of both VPCs
   - Bidirectional traffic enabled
   - Only created if `enable_vpc_peering = true`

2. **Lambda Function**
   - Name: `{name_prefix}-documentdb-va-config`
   - Runtime: Python 3.9
   - VPC: Deployed in your specified VPC and subnets
   - Purpose: Configures DocumentDB with sqlguard user

3. **IAM Role and Policy**
   - Lambda execution role with permissions for:
     - CloudWatch Logs
     - VPC networking
     - Secrets Manager access

4. **Security Groups**
   - Lambda security group
   - Secrets Manager VPC endpoint security group

5. **VPC Endpoint**
   - Secrets Manager endpoint for secure credential access

6. **Secrets Manager Secret**
   - Stores DocumentDB admin and sqlguard credentials

### DocumentDB Configuration

1. **sqlguard User**
   - Created with specified password
   - Granted roles:
     - `read` on admin database
     - `readAnyDatabase` for cluster-wide read access
     - `clusterMonitor` for monitoring capabilities

### Guardium Configuration

1. **Data Source Registration**
   - DocumentDB cluster registered in Guardium
   - Configured with connection details

2. **Vulnerability Assessment Schedule**
   - Scheduled scans based on your configuration
   - Default: Weekly on Sunday at 02:00

3. **Notifications**
   - Email notifications for high-severity findings
   - Configurable severity threshold

## Verification

### 1. Verify Lambda Execution

Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/{name_prefix}-documentdb-va-config --follow
```

### 2. Verify sqlguard User

Connect to DocumentDB and verify the user:
```bash
mongo --ssl \
  --host your-cluster.cluster-xxxxxx.region.docdb.amazonaws.com:27017 \
  --sslCAFile global-bundle.pem \
  --username sqlguard \
  --password <password> \
  --authenticationDatabase admin \
  --eval "db.runCommand({connectionStatus: 1})"
```

### 3. Verify Guardium Registration

Log into Guardium and check:
- Navigate to: **Data Sources** → **Vulnerability Assessment**
- Verify your DocumentDB cluster is listed
- Check the connection status

### 4. Test Vulnerability Assessment

Manually trigger a VA scan:
- In Guardium, go to your data source
- Click **Run Assessment Now**
- Monitor the scan progress

## Outputs

After successful deployment, Terraform will output:

```
sqlguard_username = "sqlguard"
sqlguard_password = <sensitive>
datasource_name = "rds-documentdb-va"
```

To view the sensitive password:
```bash
terraform output -raw sqlguard_password
```

## Customization

### Custom Assessment Schedule

Modify in `terraform.tfvars`:
```hcl
assessment_schedule = "daily"    # Options: daily, weekly, monthly
assessment_time     = "03:00"    # 24-hour format
assessment_day      = "Monday"   # For weekly/monthly schedules
```

### Custom Notification Settings

```hcl
enable_notifications  = true
notification_emails   = ["team@example.com", "security@example.com"]
notification_severity = "MED"  # Options: HIGH, MED, LOW, NONE
```

### SSL Configuration

```hcl
use_ssl                = true   # SSL/TLS enabled by default for secure connections
import_server_ssl_cert = true   # Import server SSL certificate for GDP registration
```

## Troubleshooting

### Lambda Function Issues

**Problem**: Lambda times out connecting to DocumentDB

**Solutions**:
- Verify Lambda is in the correct VPC and subnets
- Check security group rules allow Lambda → DocumentDB traffic
- Ensure DocumentDB cluster is in available state
- Review CloudWatch logs for detailed errors

**Check logs**:
```bash
aws logs tail /aws/lambda/{name_prefix}-documentdb-va-config --follow
```

### Connection Issues

**Problem**: "Connection refused" or timeout errors

**Solutions**:
- Verify security group allows inbound traffic on port 27017
- Check DocumentDB cluster endpoint is correct
- Ensure SSL/TLS is properly configured
- Verify network routing (VPC, subnets, route tables)

### Authentication Issues

**Problem**: Authentication failed for user 'sqlguard'

**Solutions**:
- Verify the password in Secrets Manager matches what was set
- Check the user was created successfully (review Lambda logs)
- Ensure the user has correct roles assigned
- Try connecting with admin credentials first to verify cluster access

### Guardium Connection Issues

**Problem**: Guardium cannot connect to DocumentDB

**Solutions**:
- Verify security group rule allows Guardium IP
- Test connection from Guardium server using mongo shell
- Check SSL certificate configuration
- Verify DocumentDB endpoint is accessible from Guardium

**Test from Guardium**:
```bash
# Test network connectivity
nc -zv your-cluster.cluster-xxxxxx.region.docdb.amazonaws.com 27017

# Test SSL connection
openssl s_client -connect your-cluster.cluster-xxxxxx.region.docdb.amazonaws.com:27017
```

### SSL Certificate Issues

**Problem**: SSL certificate verification failed

**Solutions**:
- Download the latest RDS CA bundle
- Verify the CA bundle path is correct
- Check that SSL is enabled on DocumentDB cluster
- Ensure the certificate is not expired

**Download CA bundle**:
```bash
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

**Note**: This will:
- Delete the Lambda function and associated resources
- Remove the Secrets Manager secret
- Delete security groups and VPC endpoints
- Unregister the data source from Guardium
- **NOT** delete the DocumentDB cluster itself
- **NOT** delete the sqlguard user from DocumentDB

To manually remove the sqlguard user from DocumentDB:
```bash
mongo --ssl \
  --host your-cluster.cluster-xxxxxx.region.docdb.amazonaws.com:27017 \
  --sslCAFile global-bundle.pem \
  --username admin \
  --password <admin-password> \
  --authenticationDatabase admin \
  --eval "db.getSiblingDB('admin').dropUser('sqlguard')"
```

## Security Best Practices

1. **Credentials Management**
   - Never commit `terraform.tfvars` to version control
   - Use AWS Secrets Manager for credential storage
   - Rotate passwords regularly
   - Use strong, unique passwords

2. **Network Security**
   - Use private subnets for Lambda functions
   - Restrict security group rules to minimum required access
   - Use VPC endpoints to avoid internet traffic
   - Enable VPC Flow Logs for monitoring

3. **DocumentDB Security**
   - Enable encryption at rest
   - Enable encryption in transit (SSL/TLS)
   - Use IAM authentication where possible
   - Enable audit logging
   - Regular security assessments

4. **Monitoring**
   - Enable CloudWatch Logs for Lambda
   - Set up CloudWatch Alarms for failures
   - Monitor DocumentDB metrics
   - Review Guardium assessment reports regularly

## Cost Considerations

This example will incur costs for:
- Lambda function execution (minimal, only runs once)
- VPC endpoints (hourly charge + data processing)
- Secrets Manager secret storage
- DocumentDB cluster (existing resource)
- Data transfer between Lambda and DocumentDB

Estimated monthly cost (excluding DocumentDB): $10-20 USD

## Additional Resources

- [AWS DocumentDB Documentation](https://docs.aws.amazon.com/documentdb/)
- [DocumentDB Best Practices](https://docs.aws.amazon.com/documentdb/latest/developerguide/best_practices.html)
- [Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs for detailed error messages
3. Consult the module README at `../../modules/aws-rds-documentdb/README.md`
4. Open an issue in the repository

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0