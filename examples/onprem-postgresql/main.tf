#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise PostgreSQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Configure Vulnerability Assessment (VA) for On-Premise PostgreSQL
#------------------------------------------------------------------------------
module "onprem_postgresql_va" {
  source = "../../modules/onprem-postgresql"

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  db_host     = var.db_host
  db_port     = var.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Guardium Data Protection Connection
  #----------------------------------------
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username
  gdp_password  = var.gdp_password
  client_id     = var.client_id
  client_secret = var.client_secret

  #----------------------------------------
  # Datasource Configuration
  #----------------------------------------
  datasource_name        = var.datasource_name
  datasource_description = var.datasource_description
  application            = var.application
  severity_level         = var.severity_level

  #----------------------------------------
  # SSL Configuration
  #----------------------------------------
  use_ssl                = var.use_ssl
  ssl_mode               = var.ssl_mode
  import_server_ssl_cert = var.import_server_ssl_cert

  #----------------------------------------
  # Vulnerability Assessment Schedule
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

  #----------------------------------------
  # Tags
  #----------------------------------------
  tags = var.tags
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "datasource_name" {
  description = "Name of the datasource registered in Guardium"
  value       = module.onprem_postgresql_va.datasource_name
}

output "datasource_host" {
  description = "Hostname of the on-premise PostgreSQL database"
  value       = module.onprem_postgresql_va.datasource_host
}

output "datasource_port" {
  description = "Port of the on-premise PostgreSQL database"
  value       = module.onprem_postgresql_va.datasource_port
}

output "vulnerability_assessment_enabled" {
  description = "Whether vulnerability assessment is enabled"
  value       = module.onprem_postgresql_va.vulnerability_assessment_enabled
}

output "assessment_schedule" {
  description = "Schedule for vulnerability assessments"
  value       = module.onprem_postgresql_va.assessment_schedule
}

output "ssl_enabled" {
  description = "Whether SSL is enabled for the connection"
  value       = module.onprem_postgresql_va.ssl_enabled
}

output "gdp_connection_status" {
  description = "Status of the Guardium Data Protection connection"
  value       = module.onprem_postgresql_va.gdp_connection_status
}