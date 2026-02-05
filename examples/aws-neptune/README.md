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

## Support

For issues or questions:
- Check the module README: `../../modules/aws-neptune/README.md`
- Review Lambda function logs in CloudWatch
- Consult Guardium documentation for VA configuration

## License

Copyright IBM Corp. 2025
SPDX-License-Identifier: Apache-2.0