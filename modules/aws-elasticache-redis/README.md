# AWS ElastiCache Redis Vulnerability Assessment Configuration Module

This Terraform module generates the datasource payload configuration for registering AWS ElastiCache Redis instances with IBM Guardium Data Protection for vulnerability assessment.

## Purpose

This module creates a JSON payload that can be used to register an AWS ElastiCache Redis cluster as a datasource in Guardium Data Protection. It handles the configuration for both TLS-enabled and non-TLS connections, and supports optional Redis AUTH token authentication.

## Prerequisites

Before using this module, ensure you have:

1. **Existing ElastiCache Redis Cluster**: A deployed and accessible AWS ElastiCache Redis cluster
2. **Guardium Data Protection Instance**: A running Guardium instance with API access
3. **Network Connectivity**: Network path between Guardium and the ElastiCache Redis endpoint
4. **Terraform**: Version 1.0.0 or higher installed

## Usage

```hcl
module "elasticache_redis_va" {
  source = "../../modules/aws-elasticache-redis"

  # Guardium Connection
  guardium_host     = "guardium.example.com"
  guardium_port     = 8443
  guardium_user     = "admin"
  guardium_password = var.guardium_password

  # ElastiCache Redis Configuration
  elasticache_cluster_id = "my-redis-cluster"
  elasticache_endpoint   = "my-redis-cluster.abc123.use1.cache.amazonaws.com"
  elasticache_port       = 6379
  aws_region             = "us-east-1"

  # Datasource Configuration
  datasource_name        = "aws-elasticache-redis-prod"
  datasource_description = "Production ElastiCache Redis cluster"
  application            = "Security Assessment"
  severity_level         = "HIGH"

  # Security Configuration
  enable_tls             = true
  import_server_ssl_cert = true
  auth_token             = var.redis_auth_token  # Optional

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| guardium_host | Hostname or IP address of the Guardium Data Protection server | `string` | n/a | yes |
| guardium_port | Port for Guardium Data Protection API connection | `number` | `8443` | no |
| guardium_user | Username for Guardium API authentication | `string` | n/a | yes |
| guardium_password | Password for Guardium API authentication | `string` | n/a | yes |
| elasticache_cluster_id | ElastiCache Redis cluster identifier | `string` | n/a | yes |
| elasticache_endpoint | ElastiCache Redis primary endpoint (without port) | `string` | n/a | yes |
| elasticache_port | ElastiCache Redis port | `number` | `6379` | no |
| aws_region | AWS region where ElastiCache Redis is deployed | `string` | n/a | yes |
| datasource_name | Name to register the ElastiCache Redis datasource in Guardium | `string` | n/a | yes |
| datasource_description | Description for the ElastiCache Redis datasource in Guardium | `string` | `"AWS ElastiCache Redis with Vulnerability Assessment"` | no |
| application | Application type for the datasource | `string` | `"Security Assessment"` | no |
| severity_level | Severity classification for the datasource (LOW, NONE, MED, HIGH) | `string` | `"MED"` | no |
| enable_tls | Enable TLS/SSL connection to ElastiCache Redis | `bool` | `true` | no |
| import_server_ssl_cert | Import ElastiCache Redis server SSL certificate automatically | `bool` | `true` | no |
| auth_token | Redis AUTH token for authentication (optional) | `string` | `null` | no |
| tags | Tags to apply to resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| datasource_payload | JSON payload for Guardium datasource registration |
| datasource_name | Name of the ElastiCache Redis datasource in Guardium |
| elasticache_endpoint | ElastiCache Redis primary endpoint |
| elasticache_port | ElastiCache Redis port |
| elasticache_cluster_id | ElastiCache Redis cluster identifier |
| aws_region | AWS region where ElastiCache Redis is deployed |
| guardium_datasource_type | Guardium datasource type for ElastiCache Redis |

## Important Notes and Assumptions

### Guardium Datasource Type

This module uses `"Redis"` as the datasource type in the Guardium payload. Depending on your Guardium version and configuration, you may need to change this to `"ElastiCache Redis"`. If datasource registration fails, verify the correct type string with your Guardium administrator or documentation.

To modify the datasource type, you can edit the template file at `templates/elasticache_redis_datasource.tpl` and change the `"type"` field.

### Redis AUTH Token

The `auth_token` variable is optional. Provide it only if your ElastiCache Redis cluster has Redis AUTH enabled. If AUTH is not enabled on your cluster, leave this variable as `null` (default).

### TLS/SSL Configuration

By default, this module assumes TLS is enabled (`enable_tls = true`). AWS ElastiCache Redis supports both TLS and non-TLS configurations. Ensure the `enable_tls` setting matches your actual cluster configuration.

### Network Access

This module does not create any AWS networking resources. Ensure that:
- Your Guardium instance can reach the ElastiCache Redis endpoint
- Security groups and network ACLs allow traffic on the Redis port (default: 6379)
- If using TLS, ensure proper certificate validation is configured

## Limitations

1. **No AWS Resource Creation**: This module does not create or modify any AWS ElastiCache resources. It only generates the configuration payload for Guardium.

2. **Testing Requirements**: Full end-to-end testing requires:
   - A real, accessible ElastiCache Redis cluster
   - A configured Guardium Data Protection instance
   - Network connectivity between Guardium and ElastiCache

3. **Payload Validation**: The module validates the JSON structure locally but cannot verify compatibility with the Guardium API without actual registration.

4. **IAM Permissions**: This module does not create IAM roles or policies. Ensure your Guardium instance has appropriate AWS credentials configured if required for ElastiCache access.

## Security Considerations

1. **Sensitive Variables**: Always mark `guardium_password` and `auth_token` as sensitive and never commit them to version control.

2. **TLS Recommended**: Keep `enable_tls = true` for production environments to ensure encrypted communication.

3. **Least Privilege**: Use read-only credentials where possible for vulnerability assessment operations.

4. **Secrets Management**: Consider using AWS Secrets Manager or similar solutions to manage sensitive credentials.

## Troubleshooting

### Datasource Registration Fails

If datasource registration fails in Guardium:
1. Verify the datasource type is correct (`"Redis"` vs `"ElastiCache Redis"`)
2. Check network connectivity from Guardium to the ElastiCache endpoint
3. Verify the AUTH token if Redis AUTH is enabled
4. Ensure TLS settings match the cluster configuration
5. Review Guardium logs for specific error messages

### Connection Issues

If Guardium cannot connect to ElastiCache:
1. Verify security group rules allow inbound traffic on the Redis port
2. Check that the endpoint address is correct and resolvable
3. Ensure the cluster is in an available state
4. Verify VPC peering or network routing if Guardium is in a different VPC/network

## License

Copyright IBM Corp. 2026
SPDX-License-Identifier: Apache-2.0
