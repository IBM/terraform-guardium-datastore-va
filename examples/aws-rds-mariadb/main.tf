# AWS RDS PostgreSQL with VA Example - Main Configuration

#------------------------------------------------------------------------------
# Step 1: Configure Vulnerability Assessment (VA) on the MariaDb database
#------------------------------------------------------------------------------
module "mariadb_va_config" {
  source = "IBM/datastore-va/guardium/modules/aws-rds-mariadb"

  name_prefix = var.name_prefix

  #----------------------------------------
  # Database Connection Details
  #----------------------------------------
  # Pass the database connection details from the mariadb module
  db_host     = var.db_host
  db_port     = var.db_port
  db_username = var.db_username
  db_password = var.db_password

  #----------------------------------------
  # VA User Configuration
  #----------------------------------------

  gdmmonitor_password = var.gdmmonitor_password

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

  client_secret = var.client_secret
  gdp_password  = var.gdp_password
  gdp_server    = var.gdp_server
  gdp_username  = var.gdp_username


  #----------------------------------------
  # Vulnerability Assessment Configuration
  #----------------------------------------

  datasource_name                = var.datasource_name
  application                    = var.application
  datasource_description         = var.datasource_description
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
}

