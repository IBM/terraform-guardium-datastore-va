# AWS RDS PostgreSQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the PostgreSQL database
#------------------------------------------------------------------------------
module "postgresql_va_config" {
  source = "IBM/datastore-va/guardium//modules/aws-rds-postgresql"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  # Pass the database connection details from the postgresql module
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
  # lambda configuration
  #----------------------------------------
  vpc_id              = var.vpc_id
  subnet_ids = var.subnet_ids


  #----------------------------------------
  # General Configuration
  #----------------------------------------
  aws_region = var.aws_region
  tags       = var.tags

}

locals {
  rds_postgres_config = templatefile("${path.module}/templates/rdsPostgresVaConf.tpl", {
    datasource_name                = var.datasource_name
    datasource_type                = "PostgreSQL"
    datasource_hostname            = var.db_host
    datasource_port                = var.db_port
    application                    = var.application
    datasource_description         = var.datasource_description
    datasource_database            = var.db_name
    connection_username            = var.db_username
    connection_password            = var.db_password
    severity_level                 = var.severity_level
    service_name                   = var.service_name
    shared_datasource              = var.shared_datasource
    connection_properties          = var.connection_properties
    compatibility_mode             = var.compatibility_mode
    custom_url                     = var.custom_url
    kerberos_config_name           = var.kerberos_config_name
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
    save_password                  = var.save_password
    use_ssl                        = var.use_ssl
    import_server_ssl_cert         = var.import_server_ssl_cert
    use_kerberos                   = var.use_kerberos
    use_ldap                       = var.use_ldap
    use_external_password          = var.use_external_password
  })
  rds_postgres_config_json_decoded = jsondecode(local.rds_postgres_config)
  rds_postgres_config_json_encoded = jsonencode(local.rds_postgres_config)
}

#------------------------------------------------------------------------------
# Step 2: Connect the PostgreSQL database to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
module "postgresql_gdp_connection" {
  count = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.rds_postgres_config_json_encoded

  client_secret = var.client_secret
  client_id = var.client_id
  gdp_password = var.gdp_password
  gdp_server = var.gdp_server
  gdp_username = var.gdp_username

  #----------------------------------------
  # Vulnerability Assessment Configuration
  #----------------------------------------
  datasource_name = var.datasource_name
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
  depends_on = [module.postgresql_va_config]
}
