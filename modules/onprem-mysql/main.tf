#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise MySQL VA Config Module - Main Configuration
# This module configures Vulnerability Assessment for on-premise MySQL databases
# without requiring AWS Lambda or other AWS services

locals {
  # SQL commands to create sqlguard user
  create_user_sql = <<-SQL
    CREATE USER IF NOT EXISTS '${var.sqlguard_username}'@'%' IDENTIFIED BY '${var.sqlguard_password}';
    GRANT SELECT ON *.* TO '${var.sqlguard_username}'@'%';
    GRANT SHOW DATABASES ON *.* TO '${var.sqlguard_username}'@'%';
    GRANT PROCESS ON *.* TO '${var.sqlguard_username}'@'%';
    FLUSH PRIVILEGES;
  SQL

  # Build the datasource configuration for Guardium
  mysql_datasource_config = templatefile("${path.module}/templates/mysql_datasource.tpl", {
    datasource_name                 = var.datasource_name
    datasource_hostname             = var.db_host
    datasource_port                 = var.db_port
    application                     = var.application
    datasource_description          = var.datasource_description
    sqlguard_username               = var.sqlguard_username
    sqlguard_password               = var.sqlguard_password
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
    aws_secrets_manager_config_name = var.aws_secrets_manager_config_name
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
}

#------------------------------------------------------------------------------
# Create sqlguard user in MySQL database
#------------------------------------------------------------------------------
# This resource executes MySQL commands locally to create the VA user
resource "null_resource" "create_sqlguard_user" {
  triggers = {
    db_host           = var.db_host
    db_port           = var.db_port
    sqlguard_username = var.sqlguard_username
    # Trigger recreation if password changes
    sqlguard_password_hash = sha256(var.sqlguard_password)
  }

  provisioner "local-exec" {
    command = <<-EOT
      mysql -h ${var.db_host} \
            -P ${var.db_port} \
            -u ${var.db_username} \
            -p'${var.db_password}' \
            ${var.use_ssl ? "--ssl-mode=REQUIRED" : ""} \
            -e "${local.create_user_sql}"
    EOT
  }
}

#------------------------------------------------------------------------------
# Connect the MySQL database to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
# This resource registers the on-premise MySQL database with Guardium
# and configures vulnerability assessment
module "mysql_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.mysql_datasource_config

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

  # Ensure sqlguard user is created before registering with Guardium
  depends_on = [null_resource.create_sqlguard_user]
}