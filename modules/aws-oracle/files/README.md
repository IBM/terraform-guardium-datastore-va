# Oracle VA Lambda Function

This directory contains the Lambda function for configuring Oracle databases for Guardium Vulnerability Assessment.

## Overview

The Lambda function:
- Connects to Oracle database using the pure Python `oracledb` library (no Oracle Instant Client required!)
- Creates the `gdmmonitor` role with necessary privileges
- Creates the `sqlguard` user for Guardium VA
- Grants appropriate permissions

## Building the Lambda Package

### Prerequisites

- Python 3.11 or later
- pip3

### Build Steps

Simply run the build script:

```bash
./build_lambda.sh
```

This will:
1. Install the `oracledb` library and dependencies
2. Package everything into `lambda_function.zip`
3. Clean up temporary files

The resulting package will be approximately 8MB.

### What Gets Packaged

- `index.py` - Lambda handler function
- `oracledb` - Pure Python Oracle database driver (thin mode)
- `cryptography` - Required by oracledb
- `cffi` - Required by cryptography
- Other dependencies

## Lambda Function Details

### Runtime
- Python 3.11
- Memory: 512 MB
- Timeout: 300 seconds (5 minutes)

### Environment Variables

The Lambda function expects these environment variables (set by Terraform):

- `SECRETS_MANAGER_SECRET_ID` - ID of the Secrets Manager secret containing credentials
- `SECRETS_REGION` - AWS region where the secret is stored
- `DB_TYPE` - Database type (set to "oracle")

### Secrets Manager Secret Format

The secret should contain:
```json
{
  "username": "admin",
  "password": "admin-password",
  "host": "oracle-host.region.rds.amazonaws.com",
  "port": "1521",
  "service_name": "ORCL",
  "sqlguard_username": "sqlguard",
  "sqlguard_password": "sqlguard-password"
}
```

## How It Works

1. **Retrieve Credentials**: Gets Oracle admin and sqlguard credentials from Secrets Manager
2. **Connect to Oracle**: Uses `oracledb` in thin mode (pure Python, no client libraries needed)
3. **Create gdmmonitor Role**: 
   - Drops existing role if present (preserving members)
   - Creates new role with required privileges
   - Grants READ on system tables
   - Grants EXECUTE on password verification functions
4. **Create sqlguard User**:
   - Creates user or updates password if exists
   - Grants CONNECT and gdmmonitor role
5. **Verify Setup**: Confirms user and role grants
6. **Return Success**: Returns detailed status information

## Advantages of oracledb (Thin Mode)

Unlike the old `cx_Oracle` approach, this implementation:

- ✅ **No Oracle Instant Client required** - Pure Python implementation
- ✅ **Smaller package size** - ~8MB vs ~50MB+ with Instant Client
- ✅ **Easier to build** - No need to download and extract Oracle libraries
- ✅ **Cross-platform** - Works on any platform with Python
- ✅ **Faster deployment** - Simpler build process
- ✅ **Better maintainability** - Fewer dependencies to manage

## Troubleshooting

### Build Issues

**Problem**: `pip: command not found`
**Solution**: Use `pip3` instead (script updated to use pip3)

**Problem**: Package too large for Lambda
**Solution**: The package should be ~8MB. If larger, ensure you're not including unnecessary files.

### Runtime Issues

Check CloudWatch Logs for detailed error messages:

```bash
aws logs tail /aws/lambda/<function-name> --region <region> --follow
```

Common issues:

1. **Connection timeout**: Check security groups and network connectivity
2. **Authentication failed**: Verify credentials in Secrets Manager
3. **Insufficient privileges**: Ensure admin user has DBA privileges
4. **Service name incorrect**: Verify the Oracle service name

### Testing Locally

You can test the Oracle connection logic locally:

```python
import oracledb

connection = oracledb.connect(
    user='admin',
    password='password',
    host='oracle-host.region.rds.amazonaws.com',
    port=1521,
    service_name='ORCL'
)

cursor = connection.cursor()
cursor.execute("SELECT 'Connected!' FROM DUAL")
print(cursor.fetchone()[0])
cursor.close()
connection.close()
```

## Deployment

After building the package, deploy with Terraform:

```bash
cd ../../../examples/aws-oracle
terraform apply
```

Terraform will:
1. Upload the new Lambda package
2. Update the Lambda function
3. Invoke the function to configure Oracle
4. Register the database with Guardium

## Maintenance

### Updating Dependencies

To update the `oracledb` library:

1. Edit `build_lambda.sh` to specify a version:
   ```bash
   pip3 install oracledb==3.4.1 -t . ...
   ```

2. Rebuild the package:
   ```bash
   ./build_lambda.sh
   ```

3. Redeploy with Terraform:
   ```bash
   terraform apply
   ```

### Modifying the Function

1. Edit `index.py`
2. Rebuild the package: `./build_lambda.sh`
3. Redeploy: `terraform apply`

## Security Considerations

- Credentials are stored in AWS Secrets Manager (encrypted at rest)
- Lambda runs in a VPC with private subnets
- VPC endpoint used for Secrets Manager access (no internet required)
- Security groups restrict network access
- IAM role follows principle of least privilege

## Support

For issues or questions:
- Check CloudWatch Logs for detailed error messages
- Review Oracle database logs
- Verify network connectivity and security groups
- Ensure credentials have appropriate privileges
