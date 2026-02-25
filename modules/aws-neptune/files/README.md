# Neptune VA Configuration Lambda Function

This directory contains the Lambda function code for configuring AWS Neptune for Guardium Vulnerability Assessment.

## Building the Lambda Package

To create the `lambda_function.zip` file with all dependencies:

```bash
# Create a temporary directory for packaging
mkdir -p package

# Install dependencies
pip install --target ./package boto3 gremlinpython

# Copy the Lambda function code
cp index.py package/

# Create the zip file
cd package
zip -r ../lambda_function.zip .
cd ..

# Clean up
rm -rf package
```

## Dependencies

- `boto3`: AWS SDK for Python (for Secrets Manager access)
- `gremlinpython`: Gremlin Python driver for Neptune graph database connectivity

## Lambda Function Overview

The Lambda function performs the following operations:

1. **Retrieve Credentials**: Fetches Neptune connection credentials from AWS Secrets Manager
2. **Connect to Neptune**: Establishes a WebSocket connection to Neptune using Gremlin protocol
3. **Configure VA Metadata**: Creates or updates VA configuration metadata in Neptune as a graph vertex
4. **Verify Configuration**: Confirms the VA setup was successful

## Neptune-Specific Considerations

Unlike traditional SQL databases, Neptune is a graph database that uses:
- **Gremlin** for property graph queries
- **SPARQL** for RDF graph queries

Neptune doesn't have traditional user management like SQL databases. Instead, this Lambda function:
- Creates a metadata vertex labeled `va_config` to track VA configuration
- Stores information about the VA setup (username, timestamp, cluster identifier)
- Can be queried by Guardium for vulnerability assessment purposes

## Environment Variables

The Lambda function expects the following environment variables:
- `SECRETS_MANAGER_SECRET_ID`: The ID/ARN of the Secrets Manager secret containing Neptune credentials
- `SECRETS_REGION`: AWS region where the secret is stored

## IAM Permissions Required

The Lambda execution role needs:
- `secretsmanager:GetSecretValue` on the Neptune credentials secret
- VPC networking permissions (if deployed in a VPC)
- CloudWatch Logs permissions for logging

## Testing

You can test the Lambda function locally or in AWS:

```python
# Test event
{
  "action": "configure_va"
}
```

## Notes

- The function is designed to be idempotent - running it multiple times is safe
- Neptune connections use WebSocket protocol (wss://)
- The function creates graph metadata rather than traditional database users
- Ensure the Lambda has network access to the Neptune cluster endpoint