#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise MySQL VA Config Module - Main Configuration
# This module configures Vulnerability Assessment for on-premise MySQL databases
# without requiring AWS Lambda or other AWS services

#------------------------------------------------------------------------------
# Terraform-Native Validations for MySQL Configuration
#------------------------------------------------------------------------------

# Validation 1: Admin user should not be 'root' (best practice)
resource "terraform_data" "validate_admin_user" {
  lifecycle {
    precondition {
      condition     = var.db_username != "root"
      error_message = <<-EOT
        ⚠️  SECURITY WARNING: Using 'root' user is not recommended!
        
        Best Practice: Create a dedicated admin user for Terraform operations.
        
        On your MySQL server, run:
          CREATE USER 'terraform_admin'@'%' IDENTIFIED WITH caching_sha2_password BY 'StrongPassword123!';
          GRANT ALL PRIVILEGES ON *.* TO 'terraform_admin'@'%' WITH GRANT OPTION;
          FLUSH PRIVILEGES;
        
        Then update terraform.tfvars:
          db_username = "terraform_admin"
          db_password = "StrongPassword123!"
      EOT
    }
  }
}

# Validation 2: Password strength check for sqlguard user (MySQL 9.6 requirements)
resource "terraform_data" "validate_sqlguard_password" {
  lifecycle {
    precondition {
      condition = (
        length(var.sqlguard_password) >= 8 &&
        can(regex("[A-Z]", var.sqlguard_password)) &&
        can(regex("[a-z]", var.sqlguard_password)) &&
        can(regex("[0-9]", var.sqlguard_password)) &&
        can(regex("[^A-Za-z0-9]", var.sqlguard_password))
      )
      error_message = <<-EOT
        ❌ ERROR: sqlguard_password does not meet MySQL 9.6 password policy requirements!
        
        MySQL 9.6 requires passwords to have:
          ✓ At least 8 characters
          ✓ At least one uppercase letter (A-Z)
          ✓ At least one lowercase letter (a-z)
          ✓ At least one number (0-9)
          ✓ At least one special character (!@#$%^&*)
        
        Example strong password: SqlGuard@2024!Strong
        
        Update terraform.tfvars:
          sqlguard_password = "SqlGuard@2024!Strong"
      EOT
    }
  }
}

# Validation 3: Ensure sqlguard user is different from admin user
resource "terraform_data" "validate_user_separation" {
  lifecycle {
    precondition {
      condition     = var.sqlguard_username != var.db_username
      error_message = <<-EOT
        ❌ ERROR: sqlguard_username cannot be the same as db_username!
        
        The sqlguard user is for Guardium VA scanning (read-only privileges).
        The db_username is for administrative operations (full privileges).
        
        These must be different users for security and least-privilege principles.
        
        Update terraform.tfvars:
          db_username       = "terraform_admin"  # Admin user
          sqlguard_username = "sqlguard"         # VA scanning user
      EOT
    }
  }
}

# Validation 4: SSL configuration check
resource "terraform_data" "validate_ssl_config" {
  lifecycle {
    precondition {
      condition     = !var.use_ssl || var.import_server_ssl_cert
      error_message = <<-EOT
        ⚠️  SECURITY WARNING: SSL is enabled but certificate verification is disabled!
        
        This configuration is vulnerable to man-in-the-middle attacks.
        
        For production environments, set:
          use_ssl                = true
          import_server_ssl_cert = true
        
        This ensures MySQL server's SSL certificate is verified by Guardium.
      EOT
    }
  }
}

# Validation 5: Port number validation
resource "terraform_data" "validate_port" {
  lifecycle {
    precondition {
      condition     = var.db_port > 0 && var.db_port <= 65535
      error_message = "db_port must be between 1 and 65535. Standard MySQL port is 3306."
    }
  }
}

# Validation 6: Hostname format validation
resource "terraform_data" "validate_hostname" {
  lifecycle {
    precondition {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.db_host))
      error_message = <<-EOT
        ❌ ERROR: db_host must be a valid hostname or IP address.
        
        Examples:
          - api.rr1.cp.fyre.ibm.com
          - mysql.example.com
          - 192.168.1.100
      EOT
    }
  }
}

locals {
  # SQL commands to create sqlguard user - Universal for MySQL 5.7+, 8.0, 9.x
  # Using caching_sha2_password for MySQL 9.x compatibility
  create_user_sql = <<-SQL
    CREATE USER IF NOT EXISTS '${var.sqlguard_username}'@'%' IDENTIFIED WITH caching_sha2_password BY '${var.sqlguard_password}';
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
            --password='${var.db_password}' \
            ${var.use_ssl ? "--ssl-mode=REQUIRED" : ""} \
            --connect-timeout=30 \
            -e "${local.create_user_sql}"
    EOT
    
    on_failure = continue
  }
  
  # Verification step to check if user was created successfully
  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      echo "Verifying sqlguard user creation..."
      mysql -h ${var.db_host} \
            -P ${var.db_port} \
            -u ${var.db_username} \
            --password='${var.db_password}' \
            ${var.use_ssl ? "--ssl-mode=REQUIRED" : ""} \
            --connect-timeout=30 \
            -e "SELECT User, Host, plugin FROM mysql.user WHERE User='${var.sqlguard_username}';" || \
      echo "⚠️  Warning: Could not verify sqlguard user creation. Please verify manually."
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