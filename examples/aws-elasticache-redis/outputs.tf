# AWS ElastiCache Redis with Vulnerability Assessment Example - Outputs

#----------------------------------------
# Datasource Information
#----------------------------------------
output "datasource_name" {
  description = "Name of the ElastiCache Redis datasource registered in Guardium"
  value       = module.elasticache_redis_va.datasource_name
}

output "datasource_payload" {
  description = "JSON payload used for Guardium datasource registration"
  value       = module.elasticache_redis_va.datasource_payload
}

#----------------------------------------
# ElastiCache Redis Configuration
#----------------------------------------
output "elasticache_cluster_id" {
  description = "ElastiCache Redis cluster identifier"
  value       = module.elasticache_redis_va.elasticache_cluster_id
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache_redis_va.elasticache_endpoint
}

output "elasticache_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache_redis_va.elasticache_port
}

output "aws_region" {
  description = "AWS region where ElastiCache Redis is deployed"
  value       = module.elasticache_redis_va.aws_region
}

#----------------------------------------
# Guardium Configuration
#----------------------------------------
output "guardium_datasource_type" {
  description = "Guardium datasource type for ElastiCache Redis"
  value       = module.elasticache_redis_va.guardium_datasource_type
}

#----------------------------------------
# Vulnerability Assessment Status
#----------------------------------------
output "vulnerability_assessment_enabled" {
  description = "Whether vulnerability assessment is enabled"
  value       = var.enable_vulnerability_assessment
}

output "assessment_schedule" {
  description = "Vulnerability assessment schedule"
  value       = var.assessment_schedule
}
