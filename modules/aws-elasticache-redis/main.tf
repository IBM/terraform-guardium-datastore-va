# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS ElastiCache Redis Vulnerability Assessment Configuration Module

#----------------------------------------
# Local variables for datasource payload processing
#----------------------------------------
locals {
  # Render the ElastiCache Redis datasource template
  elasticache_redis_config_tpl = templatefile("${path.module}/templates/elasticache_redis_datasource.tpl", {
    datasource_name                 = var.datasource_name
    elasticache_endpoint            = var.elasticache_endpoint
    elasticache_port                = var.elasticache_port
    application                     = var.application
    datasource_description          = var.datasource_description
    elasticache_cluster_id          = var.elasticache_cluster_id
    severity_level                  = var.severity_level
    enable_tls                      = var.enable_tls
    import_server_ssl_cert          = var.import_server_ssl_cert
    auth_token                      = var.auth_token
    aws_region                      = var.aws_region
    aws_secrets_manager_config_name = var.aws_secrets_manager_config_name
  })

  # Decode and re-encode JSON to normalize formatting
  elasticache_redis_config_json_decoded = jsondecode(local.elasticache_redis_config_tpl)
  elasticache_redis_config_json_encoded = jsonencode(local.elasticache_redis_config_json_decoded)
}
