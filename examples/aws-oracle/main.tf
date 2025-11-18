#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# AWS Oracle with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Oracle database
#------------------------------------------------------------------------------
module "oracle_va_config" {
  source = "../../modules/aws-oracle"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  db_host         = var.db_host
  db_port         = var.db_port
  db_service_name = var.db_service_name
  db_username     = var.db_username
  db_password     = var.db_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Lambda configuration
  #----------------------------------------
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  #----------------------------------------
  # Oracle RDS Security Group (optional)
  #----------------------------------------
  oracle_security_group_id = var.oracle_security_group_id

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  aws_region = var.aws_region
  tags       = var.tags
}

locals {
  oracle_config = templatefile("${path.module}/templates/oracleVaConf.tpl", {
    datasource_name                     = var.datasource_name
    datasource_type                     = "Oracle (DataDirect - Service Name)"
    datasource_hostname                 = var.db_host
    datasource_port                     = var.db_port
    application                         = var.application
    datasource_description              = var.datasource_description
    service_name                        = var.db_service_name
    connection_username                 = var.sqlguard_username
    connection_password                 = var.sqlguard_password
    severity_level                      = var.severity_level
    shared_datasource                   = var.shared_datasource
    connection_properties               = var.connection_properties
    compatibility_mode                  = var.compatibility_mode
    custom_url                          = var.custom_url
    kerberos_config_name                = var.kerberos_config_name
    external_password_type_name         = var.external_password_type_name
    cyberark_config_name                = var.cyberark_config_name
    cyberark_object_name                = var.cyberark_object_name
    hashicorp_config_name               = var.hashicorp_config_name
    hashicorp_path                      = var.hashicorp_path
    hashicorp_role                      = var.hashicorp_role
    hashicorp_child_namespace           = var.hashicorp_child_namespace
    aws_secrets_manager_config_name     = var.aws_secrets_manager_config_name
    region                              = var.region
    secret_name                         = var.secret_name
    db_instance_account                 = var.db_instance_account
    db_instance_directory               = var.db_instance_directory
    save_password                       = var.save_password
    use_ssl                             = var.use_ssl
    import_server_ssl_cert              = var.import_server_ssl_cert
    use_kerberos                        = var.use_kerberos
    use_ldap                            = var.use_ldap
    use_external_password               = var.use_external_password
  })
  oracle_config_json_encoded = jsonencode(jsondecode(local.oracle_config))
}

#------------------------------------------------------------------------------
# Step 2: Connect the Oracle database to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "oracle_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.oracle_config_json_encoded

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
  depends_on = [module.oracle_va_config]
}