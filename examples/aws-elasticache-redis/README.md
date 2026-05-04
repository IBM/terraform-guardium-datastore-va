# AWS ElastiCache Redis with Vulnerability Assessment Example

This example demonstrates how to register an AWS ElastiCache Redis cluster with IBM Guardium Data Protection for vulnerability assessment.

## Overview

This example:
- Generates a datasource configuration payload for ElastiCache Redis
- Registers the ElastiCache Redis cluster as a datasource in Guardium
- Configures vulnerability assessment scheduling
- Sets up notification preferences for assessment results

## Prerequisites

Before using this example, ensure you have:

1. **AWS ElastiCache Redis Cluster**
   - A deployed and running ElastiCache Redis cluster
   - Cluster endpoint and port information
   - Redis AUTH token (if AUTH is enabled on the cluster)
   - Network connectivity from Guardium to the ElastiCache endpoint

2. **IBM Guardium Data Protection Instance**
   - A running Guardium instance with API access
   - Admin credentials for API authentication
   - OAuth client configured (use `grdapi register_oauth_client`)

3. **Network Connectivity**
   - Guardium instance can reach the ElastiCache Redis endpoint
   - Security groups allow traffic on Redis port (default: 6379)
   - VPC peering or network routing configured if needed

4. **Terraform**
   - Terraform version 1.0.0 or higher installed
   - AWS credentials configured (for provider initialization)

## Usage

### Step 1: Copy the Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### Step 2: Edit terraform.tfvars

Update the `terraform.tfvars` file with your actual values:

```hcl
# Guardium Connection
gdp_server         = "your-guardium-host.example.com"
gdp_port           = 8443
guardium_username  = "admin"
guardium_password  = "your-guardium-password"
client_id          = "client1"
client_secret      = "your-oauth-client-secret"

# ElastiCache Redis Configuration
elasticache_cluster_id              = "your-redis-cluster-id"
elasticache_endpoint                = "your-redis-cluster.xxxxxx.region.cache.amazonaws.com"
elasticache_port                    = 6379
elasticache_redis_datasource_name   = "production-redis-cluster"

# Security Configuration
enable_tls             = true
import_server_ssl_cert = true
# auth_token           = "your-redis-auth-token"  # Uncomment if Redis AUTH is enabled

# Notification Configuration
notification_emails = ["security-team@example.com", "dba-team@example.com"]
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Execution Plan

```bash
terraform plan
```

### Step 5: Apply the Configuration

```bash
terraform apply
```

Review the planned changes and type `yes` to confirm.

### Step 6: Verify the Configuration

After successful application, verify:

1. **In Guardium UI:**
   - Navigate to the datasources section
   - Confirm the ElastiCache Redis datasource is registered
   - Check the vulnerability assessment schedule

2. **Check Outputs:**
   ```bash
   terraform output
   ```

## Configuration Options

### ElastiCache Redis Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `elasticache_cluster_id` | ElastiCache Redis cluster identifier | - | Yes |
| `elasticache_endpoint` | Primary endpoint (without port) | - | Yes |
| `elasticache_port` | Redis port | `6379` | No |
| `aws_region` | AWS region | `us-east-1` | No |

### Security Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_tls` | Enable TLS/SSL connection | `true` | No |
| `import_server_ssl_cert` | Auto-import SSL certificate | `true` | No |
| `auth_token` | Redis AUTH token | `null` | No* |

*Required only if Redis AUTH is enabled on your cluster

### Vulnerability Assessment Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_vulnerability_assessment` | Enable VA | `true` | No |
| `assessment_schedule` | Schedule (DAILY, WEEKLY, MONTHLY) | `WEEKLY` | No |
| `assessment_day` | Day of week for assessment | `Monday` | No |
| `assessment_time` | Time in HH:MM format | `00:00` | No |

### Notification Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_notifications` | Enable email notifications | `true` | No |
| `notification_emails` | List of email addresses | `[]` | No |
| `notification_severity` | Minimum severity (LOW, MEDIUM, HIGH, CRITICAL) | `HIGH` | No |

## Important Notes

### Guardium Datasource Type

This example uses `"Redis"` as the datasource type. Depending on your Guardium version, you may need to use `"ElastiCache Redis"` instead. If datasource registration fails with a type error:

1. Edit `../../modules/aws-elasticache-redis/templates/elasticache_redis_datasource.tpl`
2. Change the `"type"` field from `"Redis"` to `"ElastiCache Redis"`
3. Re-run `terraform apply`

### Redis AUTH Token

- Only provide `auth_token` if your ElastiCache Redis cluster has AUTH enabled
- Leave it commented out or set to `null` if AUTH is not enabled
- The token is marked as sensitive and will not appear in logs or outputs

### TLS/SSL Configuration

- AWS ElastiCache Redis supports both TLS and non-TLS configurations
- Ensure `enable_tls` matches your actual cluster configuration
- For production environments, TLS should always be enabled

### Network Access

This example does not create any AWS networking resources. Ensure:
- Security groups allow inbound traffic on the Redis port from Guardium
- Network ACLs permit the traffic
- VPC peering or transit gateway is configured if Guardium is in a different VPC
- DNS resolution works for the ElastiCache endpoint

## Outputs

After successful application, the following outputs are available:

```bash
terraform output datasource_name
terraform output elasticache_cluster_id
terraform output elasticache_endpoint
terraform output guardium_datasource_type
terraform output vulnerability_assessment_enabled
```

## Troubleshooting

### Datasource Registration Fails

**Symptom:** Terraform completes but datasource doesn't appear in Guardium

**Solutions:**
1. Verify Guardium credentials are correct
2. Check that the OAuth client secret is valid
3. Review Guardium API logs for error messages
4. Verify the datasource type is correct for your Guardium version

### Connection Issues

**Symptom:** Guardium cannot connect to ElastiCache Redis

**Solutions:**
1. Verify the endpoint address is correct and resolvable from Guardium
2. Check security group rules allow traffic on port 6379 (or your custom port)
3. Ensure the cluster is in "available" state
4. Test connectivity using `redis-cli` from a host in the same network as Guardium
5. Verify TLS settings match the cluster configuration

### Authentication Failures

**Symptom:** Connection succeeds but authentication fails

**Solutions:**
1. If Redis AUTH is enabled, ensure `auth_token` is provided and correct
2. Verify the AUTH token hasn't expired or been rotated
3. Check that the token has the necessary permissions

### SSL/TLS Issues

**Symptom:** SSL/TLS handshake failures

**Solutions:**
1. Verify `enable_tls` matches your cluster's TLS configuration
2. Ensure `import_server_ssl_cert` is set to `true`
3. Check that Guardium can validate the ElastiCache SSL certificate
4. Verify the cluster's certificate is not expired

## Cleanup

To remove the datasource registration from Guardium:

```bash
terraform destroy
```

**Note:** This will only remove the datasource registration from Guardium. It will not delete your ElastiCache Redis cluster.

## Security Best Practices

1. **Credentials Management**
   - Never commit `terraform.tfvars` to version control
   - Use environment variables or secret management tools for sensitive values
   - Rotate credentials regularly

2. **Network Security**
   - Use TLS for all connections (`enable_tls = true`)
   - Restrict security group rules to specific IP ranges
   - Use VPC endpoints where possible

3. **Access Control**
   - Use least-privilege IAM policies
   - Enable Redis AUTH for production clusters
   - Regularly review and audit access logs

4. **Monitoring**
   - Enable CloudWatch monitoring for ElastiCache
   - Set up alerts for unusual access patterns
   - Review vulnerability assessment results regularly

## Additional Resources

- [AWS ElastiCache Redis Documentation](https://docs.aws.amazon.com/elasticache/redis/)
- [IBM Guardium Data Protection Documentation](https://www.ibm.com/docs/en/guardium)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues related to:
- **This Terraform module:** Open an issue in the repository
- **Guardium Data Protection:** Contact IBM Support
- **AWS ElastiCache:** Contact AWS Support

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
