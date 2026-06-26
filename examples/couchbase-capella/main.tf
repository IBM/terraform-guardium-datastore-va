#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Couchbase Capella with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Note: AWS Secrets Manager Configuration
#------------------------------------------------------------------------------
# Couchbase Capella requires an AWS Secrets Manager configuration in Guardium.
# If you need to create a new one, uncomment the resource below and update variables.
#
# resource "guardium-data-protection_aws_secrets_manager" "couchbase_secrets_config" {
#   count = var.enable_vulnerability_assessment ? 1 : 0
#
#   access_token        = data.guardium-data-protection_authentication.auth.access_token
#   name                = var.aws_secrets_manager_config_name
#   auth_type           = "Security-Credentials"
#   access_key_id       = var.aws_access_key_id
#   secret_access_key   = var.aws_secret_access_key
#   secret_key_username = var.admin_username
#   secret_key_password = var.admin_password
# }

#------------------------------------------------------------------------------
# Optional: Reference Phase 1 Infrastructure State
#------------------------------------------------------------------------------
# Uncomment this block to reference Phase 1 Couchbase Capella deployment
# data "terraform_remote_state" "infrastructure" {
#   backend = "local"
#   config = {
#     path = "../../../scripts/couchbase-capella-deployment/terraform.tfstate"
#   }
# }

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on Couchbase Capella
#------------------------------------------------------------------------------
module "couchbase_capella_va_config" {
  source = "../../modules/couchbase-capella"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Couchbase Capella Connection Details
  #----------------------------------------
  # Option 1: Use variables directly
  cluster_endpoint  = var.cluster_endpoint
  bucket_name       = var.bucket_name
  admin_username    = var.admin_username
  admin_password    = var.admin_password
  connection_string = var.connection_string
  rest_api_endpoint = var.rest_api_endpoint
  cluster_port      = var.cluster_port

  # Option 2: Reference Phase 1 outputs (uncomment if using remote state)
  # cluster_endpoint  = data.terraform_remote_state.infrastructure.outputs.cluster_endpoint
  # bucket_name       = data.terraform_remote_state.infrastructure.outputs.bucket_name
  # admin_username    = data.terraform_remote_state.infrastructure.outputs.admin_username
  # admin_password    = data.terraform_remote_state.infrastructure.outputs.admin_password
  # connection_string = data.terraform_remote_state.infrastructure.outputs.connection_string
  # rest_api_endpoint = data.terraform_remote_state.infrastructure.outputs.rest_api_endpoint

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Lambda Configuration
  #----------------------------------------
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  aws_region        = var.aws_region
  guardium_hostname = var.guardium_hostname
  tags              = var.tags
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
  # Use the existing AWS Secrets Manager config name if provided
  aws_secrets_config_name = var.enable_vulnerability_assessment ? var.aws_secrets_manager_config_name : ""

  # Determine database name (use bucket_name if datasource_database is empty)
  database_name = var.datasource_database != "" ? var.datasource_database : var.bucket_name

  couchbase_config = templatefile("${path.module}/templates/couchbaseCapellaVaConf.tpl", {
    datasource_name                 = var.datasource_name
    datasource_type                 = "Couchbase Capella"
    datasource_hostname             = var.cluster_endpoint
    datasource_port                 = var.cluster_port
    application                     = var.application
    datasource_description          = var.datasource_description
    datasource_database             = local.database_name
    connection_username             = var.admin_username
    connection_password             = var.admin_password
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
  couchbase_config_json_decoded = jsondecode(local.couchbase_config)
  couchbase_config_json_encoded = jsonencode(local.couchbase_config_json_decoded)
}

#------------------------------------------------------------------------------
# Step 2: Connect Couchbase Capella to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "couchbase_capella_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.couchbase_config_json_encoded

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
  depends_on = [module.couchbase_capella_va_config]
}
