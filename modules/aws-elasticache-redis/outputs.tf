# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS ElastiCache Redis Vulnerability Assessment Configuration Module - Outputs

#----------------------------------------
# Datasource Payload Outputs
#----------------------------------------
output "datasource_payload" {
  description = "JSON payload for Guardium datasource registration"
  value       = local.elasticache_redis_config_json_encoded
  sensitive   = true
}

output "datasource_name" {
  description = "Name of the ElastiCache Redis datasource in Guardium"
  value       = var.datasource_name
}

#----------------------------------------
# ElastiCache Configuration Outputs
#----------------------------------------
output "elasticache_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = var.elasticache_endpoint
}

output "elasticache_port" {
  description = "ElastiCache Redis port"
  value       = var.elasticache_port
}

output "elasticache_cluster_id" {
  description = "ElastiCache Redis cluster identifier"
  value       = var.elasticache_cluster_id
}

output "aws_region" {
  description = "AWS region where ElastiCache Redis is deployed"
  value       = var.aws_region
}

#----------------------------------------
# Datasource Type Output
#----------------------------------------
output "guardium_datasource_type" {
  description = "Guardium datasource type for ElastiCache Redis"
  value       = "Redis"
}
