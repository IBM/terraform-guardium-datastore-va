#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# AWS Neptune with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Note: AWS Secrets Manager Configuration
#------------------------------------------------------------------------------
# Neptune requires an AWS Secrets Manager configuration in Guardium.
# This example uses an existing configuration named "matt".
# If you need to create a new one, uncomment the resource below and update variables.
#
# resource "guardium-data-protection_aws_secrets_manager" "neptune_secrets_config" {
#   count = var.enable_vulnerability_assessment ? 1 : 0
#
#   access_token        = data.guardium-data-protection_authentication.auth.access_token
#   name                = var.aws_secrets_manager_config_name
#   auth_type           = "Security-Credentials"
#   access_key_id       = var.aws_access_key_id
#   secret_access_key   = var.aws_secret_access_key
#   secret_key_username = var.db_username
#   secret_key_password = var.db_password
# }

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the Neptune database
#------------------------------------------------------------------------------
module "neptune_va_config" {
  source = "../../modules/aws-neptune"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  # Pass the database connection details from the Neptune cluster
  neptune_cluster_endpoint   = var.neptune_cluster_endpoint
  neptune_cluster_port       = var.neptune_cluster_port
  neptune_cluster_identifier = var.neptune_cluster_identifier
  db_username                = var.db_username
  db_password                = var.db_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Lambda configuration
  #----------------------------------------
  vpc_id                    = var.vpc_id
  neptune_security_group_id = var.neptune_security_group_id
  neptune_port              = var.neptune_port
  subnet_ids                = var.subnet_ids

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  aws_region = var.aws_region
  tags       = var.tags
}

#------------------------------------------------------------------------------
# Authentication Data Source
#------------------------------------------------------------------------------
data "guardium-data-protection_authentication" "auth" {
  username      = var.gdp_username
  password      = var.gdp_password
  client_id     = var.client_id
  client_secret = var.client_secret
}

locals {
  # Use the existing AWS Secrets Manager config name "matt"
  aws_secrets_config_name = var.enable_vulnerability_assessment ? var.aws_secrets_manager_config_name : ""

  neptune_config = templatefile("${path.module}/templates/neptuneVaConf.tpl", {
    datasource_name                 = var.datasource_name
    datasource_type                 = "Amazon Neptune"
    datasource_hostname             = var.neptune_cluster_endpoint
    datasource_port                 = var.neptune_cluster_port
    application                     = var.application
    datasource_description          = var.datasource_description
    datasource_database             = var.datasource_database
    connection_username             = var.db_username
    connection_password             = var.db_password
    severity_level                  = var.severity_level
    service_name                    = var.service_name
    shared_datasource               = var.shared_datasource
    connection_properties           = var.connection_properties
    compatibility_mode              = var.compatibility_mode
    custom_url                      = var.custom_url
    kerberos_config_name            = var.kerberos_config_name
    external_password_type_name     = var.external_password_type_name
    cyberark_config_name            = var.cyberark_config_name
    cyberark_object_name            = var.cyberark_object_name
    hashicorp_config_name           = var.hashicorp_config_name
    hashicorp_path                  = var.hashicorp_path
    hashicorp_role                  = var.hashicorp_role
    hashicorp_child_namespace       = var.hashicorp_child_namespace
    aws_secrets_manager_config_name = local.aws_secrets_config_name
    region                          = var.region
    secret_name                     = var.secret_name
    db_instance_account             = var.db_instance_account
    db_instance_directory           = var.db_instance_directory
    save_password                   = var.save_password
    use_ssl                         = var.use_ssl
    import_server_ssl_cert          = var.import_server_ssl_cert
    use_kerberos                    = var.use_kerberos
    use_ldap                        = var.use_ldap
    use_external_password           = var.use_external_password
  })
  neptune_config_json_decoded = jsondecode(local.neptune_config)
  neptune_config_json_encoded = jsonencode(local.neptune_config_json_decoded)
}

#------------------------------------------------------------------------------
# Step 2: Connect the Neptune database to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "neptune_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.neptune_config_json_encoded

  client_secret = var.client_secret
  client_id     = var.client_id
  gdp_password  = var.gdp_password
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username

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
  depends_on = [module.neptune_va_config]
}