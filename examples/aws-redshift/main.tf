# AWS Redshift with VA Example - Main Configuration
# This example uses an existing Redshift cluster

# AWS Redshift with VA Example - Main Configuration
# This example uses an existing Redshift cluster

#------------------------------------------------------------------------------
# Step 1: Reference the existing Redshift cluster
#------------------------------------------------------------------------------
# Use data sources to get information about the existing Redshift cluster
data "aws_redshift_cluster" "existing" {
  cluster_identifier = var.redshift_cluster_identifier
}

# Local variables to store Redshift cluster information
locals {
  redshift_endpoint       = data.aws_redshift_cluster.existing.endpoint
  redshift_hostname       = split(":", local.redshift_endpoint)[0]
  redshift_port           = try(split(":", local.redshift_endpoint)[1], var.redshift_port)
  redshift_database_name  = var.redshift_database_name
  redshift_master_username = var.redshift_master_username
  redshift_master_password = var.redshift_master_password

  # Use the first 6 characters of the original name prefix to avoid exceeding AWS IAM role name length limits
  unique_name_prefix = substr(var.name_prefix, 0, 6)

  # Generate the Redshift configuration JSON payload for Guardium
  redshift_config = templatefile("${path.module}/templates/redshiftVaConf.tpl", {
    datasource_name                = var.datasource_name
    datasource_type                = "Amazon Redshift"
    datasource_hostname            = local.redshift_hostname
    datasource_port                = local.redshift_port
    application                    = var.application
    datasource_description         = var.datasource_description
    datasource_database            = local.redshift_database_name
    connection_username            = var.sqlguard_username
    connection_password            = var.sqlguard_password
    severity_level                 = var.severity_level

    # Optional parameters with empty defaults
    service_name                   = ""
    shared_datasource              = "Not Shared"
    connection_properties          = var.connection_properties
    compatibility_mode             = var.compatibility_mode
    custom_url                     = var.custom_url
    kerberos_config_name           = ""
    external_password_type_name    = var.external_password_type_name
    cyberark_config_name           = var.cyberark_config_name
    cyberark_object_name           = var.cyberark_object_name
    hashicorp_config_name          = var.hashicorp_config_name
    hashicorp_path                 = var.hashicorp_path
    hashicorp_role                 = var.hashicorp_role
    hashicorp_child_namespace      = var.hashicorp_child_namespace
    aws_secrets_manager_config_name = var.aws_secrets_manager_config_name
    region                         = var.region
    secret_name                    = var.secret_name
    db_instance_account            = var.db_instance_account
    db_instance_directory          = var.db_instance_directory

    # Boolean parameters
    save_password                  = var.save_password
    use_ssl                        = var.use_ssl
    import_server_ssl_cert         = var.import_server_ssl_cert
    use_kerberos                   = var.use_kerberos
    use_ldap                       = var.use_ldap
    use_external_password          = var.use_external_password
  })

  # Properly encode the configuration as JSON
  redshift_config_json = local.redshift_config
}

#------------------------------------------------------------------------------
# Step 2: Configure Vulnerability Assessment (VA) on the Redshift cluster
#------------------------------------------------------------------------------
module "redshift_va_config" {
  source = "IBM/datastore-va/guardium//modules/aws-redshift"

  #----------------------------------------
  # General Configuration
  #----------------------------------------
  name_prefix = local.unique_name_prefix
  aws_region  = var.aws_region
  tags        = var.tags

  #----------------------------------------
  # Redshift Connection Details
  #----------------------------------------
  redshift_host     = local.redshift_hostname
  redshift_port     = local.redshift_port
  redshift_database = local.redshift_database_name
  redshift_username = local.redshift_master_username
  redshift_password = var.redshift_master_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------
  sqlguard_username = var.sqlguard_username
  sqlguard_password = var.sqlguard_password

  #----------------------------------------
  # Network Configuration for Lambda
  #----------------------------------------
  vpc_id                   = var.vpc_id
  subnet_id                = var.subnet_id
  allowed_egress_cidr_blocks = var.allowed_egress_cidr_blocks
}

#------------------------------------------------------------------------------
# Step 3: Connect the Redshift cluster to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "redshift_gdp_connection" {
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  #----------------------------------------
  # Guardium Connection Details
  #----------------------------------------
  gdp_server            = var.gdp_server
  gdp_port              = var.gdp_port
  gdp_username          = var.gdp_username
  gdp_password          = var.gdp_password
  client_id             = var.client_id
  client_secret         = var.client_secret

  #----------------------------------------
  # Data Source Configuration - Using JSON payload
  #----------------------------------------
  datasource_name        = var.datasource_name
  datasource_payload     = local.redshift_config_json

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

  #----------------------------------------
  # Tags
  #----------------------------------------
  tags = var.tags

  # Depends on the VA configuration being completed
  depends_on = [module.redshift_va_config]
}
