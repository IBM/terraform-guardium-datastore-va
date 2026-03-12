#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS Aurora MySQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Aurora MySQL cluster
#------------------------------------------------------------------------------
module "aurora_mysql_va_config" {
  source = "../../modules/aws-aurora-mysql"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  # Pass the database connection details from the Aurora cluster
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
  # Lambda configuration
  #----------------------------------------

  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  db_security_group_id = var.db_security_group_id


  #----------------------------------------
  # General Configuration
  #----------------------------------------
  aws_region = var.aws_region
  tags       = var.tags
}

locals {
  aurora_mysql_config = templatefile("${path.module}/templates/auroraMysqlVaConf.tpl", {
    datasource_name                 = var.datasource_name
    datasource_hostname             = var.db_host
    datasource_port                 = var.db_port
    application                     = var.application
    datasource_description          = var.datasource_description
    sqlguard_username               = var.sqlguard_username
    sqlguard_password               = var.sqlguard_password
    severity_level                  = var.severity_level
    external_password_type_name     = var.external_password_type_name
    aws_secrets_manager_config_name = var.aws_secrets_manager_config_name
    region                          = var.region
    secret_name                     = var.secret_name
    use_ssl                         = var.use_ssl
    import_server_ssl_cert          = var.import_server_ssl_cert
    use_external_password           = var.use_external_password
  })
  aurora_mysql_config_json_decoded = jsondecode(local.aurora_mysql_config)
  aurora_mysql_config_json_encoded = jsonencode(local.aurora_mysql_config)
}

#------------------------------------------------------------------------------
# Step 2: Connect the Aurora MySQL cluster to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "aurora_mysql_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.aurora_mysql_config_json_encoded

  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username
  gdp_port      = var.gdp_port

  #----------------------------------------
  # Vulnerability Assessment Configuration
  #----------------------------------------
  datasource_name                 = var.datasource_name
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

  # Depends on the VA configuration being completed
  depends_on = [module.aurora_mysql_va_config]
}