# AWS Oracle with Guardium Vulnerability Assessment Example

This example demonstrates how to configure an existing AWS RDS Oracle or Oracle Autonomous Database for Guardium Vulnerability Assessment (VA) and connect it to Guardium Data Protection (GDP).

## Overview

This example performs the following steps:

1. **Configure VA on Oracle**: Creates the `gdmmonitor` role and grants necessary permissions using a Lambda function that executes PL/SQL
2. **Create VA User**: Creates the `sqlguard` user and grants the `gdmmonitor` role
3. **Register with Guardium**: Connects the Oracle database to Guardium Data Protection and configures vulnerability assessment schedules

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC                                    │  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │  Lambda Function│────────▶│  Oracle Database     │   │  │
│  │  │  (VA Config)    │         │  (RDS/Autonomous)    │   │  │
│  │  │  + cx_Oracle    │         │                      │   │  │
│  │  └────────┬────────┘         └──────────────────────┘   │  │
│  │           │                                              │  │
│  │           │                                              │  │
│  │  ┌────────▼────────┐         ┌──────────────────────┐   │  │
│  │  │  Secrets Manager│         │  VPC Endpoint        │   │  │
│  │  │  (Credentials)  │◀────────│  (Secrets Manager)   │   │  │
│  │  └─────────────────┘         └──────────────────────┘   │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
                    ┌──────────────────┐
                    │   Guardium Data  │
                    │   Protection     │
                    │   (GDP)          │
                    └──────────────────┘
```

## Prerequisites

Before using this example, ensure you have:

1. **Existing Oracle Database**:
   - RDS Oracle or Oracle Autonomous Database
   - Admin user with DBA privileges (or ADMIN for Autonomous)
   - Database accessible from VPC subnets

2. **AWS Infrastructure**:
   - VPC with private subnets
   - Subnets with connectivity to the Oracle database
   - Security groups allowing Lambda to connect to Oracle (port 1521 or 1522)

3. **Guardium Data Protection**:
   - Guardium server accessible from your network
   - Admin credentials for Guardium
   - OAuth client credentials (generated using `grdapi register_oauth_client`)

4. **Terraform**:
   - Terraform >= 1.0.0
   - AWS provider >= 5.0
   - Appropriate AWS credentials configured

5. **Lambda Function Package**:
   - **IMPORTANT**: You must build the Lambda function package with Oracle Instant Client and cx_Oracle
   - See "Building the Lambda Function" section below

## Building the Lambda Function

The Lambda function requires Oracle Instant Client libraries and the cx_Oracle Python package. You must build this package before deploying:

```bash
# Navigate to the module directory
cd ../../modules/aws-oracle/files

# Create a build directory
mkdir -p lambda_build
cd lambda_build

# Install cx_Oracle for Lambda (Python 3.9)
pip install cx_Oracle -t . --platform manylinux2014_x86_64 --only-binary=:all:

# Download Oracle Instant Client Basic Light (19.x or later)
# From: https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html
wget https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basiclite-linux.x64-19.23.0.0.0dbru.zip

# Extract Instant Client
unzip instantclient-basiclite-linux.x64-19.23.0.0.0dbru.zip
mv instantclient_19_23 instantclient

# Create the Lambda handler (index.py)
cat > index.py << 'EOF'
import json
import boto3
import cx_Oracle
import os

def handler(event, context):
    # Get credentials from Secrets Manager
    secrets_client = boto3.client('secretsmanager', region_name=os.environ['SECRETS_REGION'])
    secret = secrets_client.get_secret_value(SecretId=os.environ['SECRETS_MANAGER_SECRET_ID'])
    creds = json.loads(secret['SecretString'])
    
    # Set Oracle environment
    os.environ['LD_LIBRARY_PATH'] = '/opt/instantclient'
    
    # Connect to Oracle
    dsn = cx_Oracle.makedsn(creds['host'], creds['port'], service_name=creds['service_name'])
    connection = cx_Oracle.connect(creds['username'], creds['password'], dsn)
    cursor = connection.cursor()
    
    # Read and execute the PL/SQL script
    with open('/opt/oracle-va-config.sql', 'r') as f:
        plsql_script = f.read()
    
    cursor.execute(plsql_script)
    
    # Create sqlguard user and grant gdmmonitor role
    cursor.execute(f"CREATE USER {creds['sqlguard_username']} IDENTIFIED BY {creds['sqlguard_password']}")
    cursor.execute(f"GRANT CONNECT TO {creds['sqlguard_username']}")
    cursor.execute(f"GRANT gdmmonitor TO {creds['sqlguard_username']}")
    
    connection.commit()
    cursor.close()
    connection.close()
    
    return {
        'statusCode': 200,
        'body': json.dumps('Oracle VA configuration completed successfully')
    }
EOF

# Copy the PL/SQL script
cp ../scripts/oracle-va-config.sql .

# Create the deployment package
zip -r ../lambda_function.zip . -x "*.zip"

# Clean up
cd ..
rm -rf lambda_build
```

## Usage

### Step 1: Find Required AWS Resource IDs

Before configuring the variables, you need to identify your Oracle database's network configuration. Use these AWS CLI commands:

#### Get Oracle Database Details
```bash
# Replace 'your-db-instance-id' with your actual Oracle RDS instance identifier
aws rds describe-db-instances \
  --db-instance-identifier your-db-instance-id \
  --region us-east-2 \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,MasterUsername:MasterUsername,DBName:DBName,VpcId:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName,SecurityGroups:VpcSecurityGroups[*].VpcSecurityGroupId}' \
  --output json
```

This returns:
- **Endpoint**: Database hostname (use for `db_host`)
- **Port**: Database port (use for `db_port`)
- **MasterUsername**: Admin username (use for `db_username`)
- **DBName**: Service name (use for `db_service_name`)
- **VpcId**: VPC ID (use for `vpc_id`)
- **SubnetGroup**: DB subnet group name (needed for next command)
- **SecurityGroups**: Security group IDs

#### Get Subnet IDs
```bash
# Replace 'your-subnet-group-name' with the SubnetGroup value from above
aws rds describe-db-subnet-groups \
  --db-subnet-group-name your-subnet-group-name \
  --region us-east-2 \
  --query 'DBSubnetGroups[0].Subnets[*].SubnetIdentifier' \
  --output json
```

This returns the subnet IDs to use for `subnet_ids`.

**Example for guardium-oracle database:**
```bash
# Get database details
aws rds describe-db-instances \
  --db-instance-identifier guardium-oracle \
  --region us-east-2 \
  --query 'DBInstances[0].{Endpoint:Endpoint.Address,Port:Endpoint.Port,MasterUsername:MasterUsername,DBName:DBName,VpcId:DBSubnetGroup.VpcId,SubnetGroup:DBSubnetGroup.DBSubnetGroupName,SecurityGroups:VpcSecurityGroups[*].VpcSecurityGroupId}' \
  --output json

# Get subnet IDs
aws rds describe-db-subnet-groups \
  --db-subnet-group-name guardium-oracle-subnet-group \
  --region us-east-2 \
  --query 'DBSubnetGroups[0].Subnets[*].SubnetIdentifier' \
  --output json
```

### Step 2: Build Lambda Function Package

Follow the "Building the Lambda Function" section above to create `lambda_function.zip`.

### Step 3: Configure Variables

Copy the example tfvars file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Oracle Configuration
db_host         = "your-oracle-db.xxxxx.us-east-1.rds.amazonaws.com"
db_port         = 1521
db_service_name = "ORCL"
db_username     = "admin"
db_password     = "your-secure-password"

# Network Configuration
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

# Guardium Configuration
gdp_server    = "guardium.example.com"
gdp_username  = "admin"
gdp_password  = "your-guardium-password"
client_secret = "your-client-secret"

# VA User Configuration
sqlguard_password = "your-sqlguard-password"
```

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

### Step 7: Verify the Configuration

After successful deployment, verify:

1. **Lambda Function**: Check CloudWatch Logs for successful execution
2. **Oracle User**: Connect to Oracle and verify:
   ```sql
   SELECT USERNAME FROM DBA_USERS WHERE USERNAME = 'SQLGUARD';
   SELECT ROLE FROM DBA_ROLES WHERE ROLE = 'GDMMONITOR';
   SELECT GRANTED_ROLE FROM DBA_ROLE_PRIVS WHERE GRANTEE = 'SQLGUARD';
   ```
3. **Guardium Registration**: Log into Guardium and verify the datasource appears
4. **VA Schedule**: Check that the vulnerability assessment schedule is configured

## What Gets Created

This example creates the following resources:

### AWS Resources

1. **Lambda Function**: Executes PL/SQL to configure VA on Oracle (512 MB memory for Oracle client)
2. **IAM Role & Policy**: Permissions for Lambda to access Secrets Manager and create network interfaces
3. **Security Groups**: 
   - Lambda security group (allows outbound to Oracle)
   - Secrets Manager VPC endpoint security group
4. **Secrets Manager Secret**: Stores Oracle and sqlguard credentials securely
5. **VPC Endpoint**: Allows Lambda to access Secrets Manager from private subnets

### Oracle Database Objects

1. **gdmmonitor Role**: Role with necessary privileges for VA
2. **sqlguard User**: User account for Guardium VA
3. **Grants**: Various system privileges and READ permissions on system tables

### Guardium Configuration

1. **Datasource Registration**: Registers Oracle database in Guardium
2. **VA Schedule**: Configures vulnerability assessment schedule
3. **Notifications**: Sets up email notifications for assessment results

## Outputs

After successful deployment, the following outputs are available:

```hcl
sqlguard_username          # Username for the Guardium VA user
lambda_function_arn        # ARN of the Lambda function
lambda_function_name       # Name of the Lambda function
security_group_id          # Security group ID for Lambda
va_config_completed        # VA configuration status
secrets_manager_secret_arn # ARN of the Secrets Manager secret
gdmmonitor_role_created    # Confirmation message
datasource_name            # Name of the datasource in Guardium
gdp_connection_status      # Connection status to Guardium
```

## Important Notes

### Oracle-Specific Considerations

1. **Service Name**: 
   - RDS Oracle: Usually the database name (e.g., `ORCL`, `ORCLPDB1`)
   - Autonomous: Service name with suffix (e.g., `mydb_high`, `mydb_medium`, `mydb_low`)

2. **Port**:
   - RDS Oracle: Default is 1521
   - Autonomous: Usually 1522

3. **Admin Privileges**:
   - RDS Oracle: User must have DBA privileges
   - Autonomous: Use ADMIN user

4. **PL/SQL Script**: The script creates the `gdmmonitor` role with:
   - CONNECT privilege
   - SELECT_CATALOG_ROLE
   - READ permissions on system tables
   - EXECUTE on password verification functions

### Lambda Function Requirements

- **Memory**: 512 MB (Oracle Instant Client requires more resources than PostgreSQL)
- **Timeout**: 300 seconds (5 minutes)
- **Runtime**: Python 3.9
- **Dependencies**: cx_Oracle, Oracle Instant Client Basic Light
- **VPC**: Must be deployed in VPC with Oracle connectivity

### Security Best Practices

1. **Credentials Management**:
   - Never commit `terraform.tfvars` to version control
   - Use environment variables or AWS Secrets Manager for sensitive values
   - Rotate passwords regularly

2. **Network Security**:
   - Ensure Oracle security group only allows connections from Lambda security group
   - Use private subnets for Lambda deployment
   - Enable VPC Flow Logs for network monitoring

3. **IAM Permissions**:
   - Follow principle of least privilege
   - Review and audit IAM policies regularly

### Troubleshooting

#### Lambda Function Fails

1. Check CloudWatch Logs:
   ```bash
   aws logs tail /aws/lambda/<function-name> --follow
   ```

2. Common issues:
   - Oracle Instant Client not found: Verify `LD_LIBRARY_PATH` is set correctly
   - cx_Oracle import error: Ensure cx_Oracle is compiled for the correct platform
   - Connection timeout: Check security groups and network connectivity

#### Oracle Connection Fails

1. Verify service name is correct
2. Check Oracle listener is running
3. Verify credentials have DBA privileges
4. Test connection from Lambda subnet

#### Role Creation Fails

1. Ensure admin user has sufficient privileges
2. Check Oracle database is not in restricted mode
3. Verify PL/SQL script syntax is compatible with Oracle version

#### Terraform State Issues

##### Security Group Already Exists Error
```
Error: creating Security Group (oracle-monitoring-oracle-va-config-lambda-sg):
operation error EC2: CreateSecurityGroup, api error InvalidGroup.Duplicate:
The security group 'oracle-monitoring-oracle-va-config-lambda-sg' already exists
```

**Cause**: Security group exists in AWS but not in Terraform state (usually after a failed destroy).

**Solution**: Import the existing security group into Terraform state:
```bash
# Find the security group ID
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=oracle-monitoring-oracle-va-config-lambda-sg" \
  --region us-east-2 \
  --query 'SecurityGroups[0].GroupId' \
  --output text

# Import it (replace sg-xxxxx with actual ID)
terraform import module.oracle_va_config.aws_security_group.lambda_sg sg-xxxxx
```

##### Duplicate Security Group Rule Error
```
Error: [WARN] A duplicate Security Group rule was found on (sg-xxxxx).
api error InvalidPermission.Duplicate: the specified rule already exists
```

**Cause**: Security group rule exists in AWS but not in Terraform state.

**Solution**: Import the existing rule:
```bash
# Import the rule (adjust the ID format based on your configuration)
terraform import 'module.oracle_va_config.aws_security_group_rule.lambda_to_oracle[0]' \
  sg-033ba0f72eebae4f1_ingress_tcp_1521_1521_sg-0be7933a2b5b897b4
```

The rule ID format is: `{security_group_id}_{type}_{protocol}_{from_port}_{to_port}_{source_sg_id}`

##### Security Group Stuck Destroying
```
module.oracle_va_config.aws_security_group.lambda_sg: Still destroying... [4m0s elapsed]
```

**Cause**: AWS Lambda ENIs (Elastic Network Interfaces) take 5-10 minutes to fully release after Lambda deletion.

**Solutions**:

1. **Wait it out** (recommended): Terraform will succeed once AWS releases the ENIs
2. **Check for dependencies**:
   ```bash
   # Check for attached network interfaces
   aws ec2 describe-network-interfaces \
     --filters "Name=group-id,Values=sg-xxxxx" \
     --region us-east-2
   
   # Check for Lambda functions using the security group
   aws lambda list-functions --region us-east-2 \
     --query "Functions[?VpcConfig.SecurityGroupIds[?contains(@, 'sg-xxxxx')]].FunctionName"
   ```

3. **Force cleanup** (if stuck for >10 minutes):
   ```bash
   # Try to delete manually
   aws ec2 delete-security-group --group-id sg-xxxxx --region us-east-2
   
   # If it fails, wait 5 more minutes and try again
   ```

##### Re-running Guardium Registration

If you need to re-register with Guardium (e.g., after fixing connectivity issues):

```bash
# Remove the Guardium connection from state
terraform state rm 'module.oracle_gdp_connection[0].guardium-data-protection_register_va_datasource.register_va_datasource'

# Re-apply to register again
terraform apply
```

##### Complete State Reset

If Terraform state is completely corrupted:

```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Remove all resources from state
terraform state list | xargs -n1 terraform state rm

# Re-import or recreate resources
terraform apply
```

**Warning**: Only use complete state reset as a last resort. You may need to manually clean up AWS resources first.

## Cleanup

To remove all resources created by this example:

```bash
terraform destroy
```

**Note**: This will:
- Delete the Lambda function and associated resources
- Remove the Secrets Manager secret (immediate deletion)
- **NOT** delete the Oracle database itself
- **NOT** remove the `gdmmonitor` role or `sqlguard` user from Oracle

To manually clean up Oracle objects:

```sql
DROP USER sqlguard CASCADE;
DROP ROLE gdmmonitor;
```

## Cost Considerations

This example incurs the following AWS costs:

- **Lambda**: Pay per invocation (one-time setup cost, minimal)
- **Secrets Manager**: ~$0.40/month per secret
- **VPC Endpoint**: ~$7.20/month for Secrets Manager endpoint
- **CloudWatch Logs**: Based on log retention and volume

## Support

For issues or questions:

1. Check the [main README](../../README.md) for general information
2. Review the [module documentation](../../modules/aws-oracle/README.md)
3. Consult Oracle documentation for database-specific issues
4. Open an issue in the GitHub repository

## License

This example is provided under the same license as the main module.