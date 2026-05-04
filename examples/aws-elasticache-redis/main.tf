# AWS ElastiCache Redis with Vulnerability Assessment Example

#----------------------------------------
# No Provider Configuration Here
# Providers are configured in provider.tf
#----------------------------------------

#----------------------------------------
# ElastiCache Redis Vulnerability Assessment Configuration
#----------------------------------------
module "elasticache_redis_va" {
  source = "../../modules/aws-elasticache-redis"

  # Guardium Connection
  guardium_host     = var.gdp_server
  guardium_port     = var.gdp_port
  guardium_user     = var.guardium_username
  guardium_password = var.guardium_password

  # ElastiCache Redis Configuration
  elasticache_cluster_id = var.elasticache_cluster_id
  elasticache_endpoint   = var.elasticache_endpoint
  elasticache_port       = var.elasticache_port
  aws_region             = var.aws_region

  # Datasource Configuration
  datasource_name        = var.elasticache_redis_datasource_name
  datasource_description = var.elasticache_redis_description
  application            = var.application
  severity_level         = var.severity_level

  # Security Configuration
  enable_tls             = var.enable_tls
  import_server_ssl_cert = var.import_server_ssl_cert
  auth_token             = var.auth_token

  # Tags
  tags = var.tags
}

#----------------------------------------
# Connect ElastiCache Redis to Guardium Data Protection
#----------------------------------------
module "elasticache_redis_gdp_connection" {
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  #----------------------------------------
  # Guardium Connection Details
  #----------------------------------------
  gdp_server    = var.gdp_server
  gdp_port      = var.gdp_port
  gdp_username  = var.guardium_username
  gdp_password  = var.guardium_password
  client_id     = var.client_id
  client_secret = var.client_secret

  #----------------------------------------
  # Datasource Information
  #----------------------------------------
  datasource_name = var.elasticache_redis_datasource_name

  # Use the encoded JSON payload from the module
  datasource_payload = module.elasticache_redis_va.datasource_payload

  #----------------------------------------
  # Vulnerability Assessment Configuration
  #----------------------------------------
  enable_vulnerability_assessment = var.enable_vulnerability_assessment
  assessment_schedule             = var.assessment_schedule
  assessment_day                  = var.assessment_day
  assessment_time                 = var.assessment_time

  #----------------------------------------
  # Notification Configuration
  #----------------------------------------
  enable_notifications  = var.enable_notifications
  notification_emails   = var.notification_emails
  notification_severity = var.notification_severity

  # Tags
  tags = var.tags

  # Dependencies
  depends_on = [module.elasticache_redis_va]
}
