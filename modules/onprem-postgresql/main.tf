#
# Copyright IBM Corp. 2025
# SPDX-License-Identifier: Apache-2.0
#

# On-Premise PostgreSQL VA Config Module - Main Configuration
# This module configures Vulnerability Assessment for on-premise PostgreSQL databases
# without requiring AWS Lambda or other AWS services

#------------------------------------------------------------------------------
# Terraform-Native Validations for PostgreSQL Configuration
#------------------------------------------------------------------------------

# Validation 1: Admin user should not be 'postgres' (best practice warning)
# Note: This is a warning, not a hard error. Using postgres user is allowed but not recommended.
resource "terraform_data" "validate_admin_user" {
  lifecycle {
    precondition {
      condition     = var.db_username == "postgres" ? true : true
      error_message = "This validation always passes - it's for documentation only"
    }
  }
  
  provisioner "local-exec" {
    command = var.db_username == "postgres" ? "echo '⚠️  WARNING: Using postgres superuser. Consider creating a dedicated admin user for better security.'" : "echo 'Using dedicated admin user: ${var.db_username}'"
  }
}

# Validation 2: Password strength check for sqlguard user (PostgreSQL 16 recommendations)
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
        ❌ ERROR: sqlguard_password does not meet PostgreSQL security best practices!
        
        PostgreSQL recommends passwords to have:
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
        The db_username is for administrative operations (superuser privileges).
        
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
      condition     = !var.use_ssl || var.ssl_mode != "disable"
      error_message = <<-EOT
        ⚠️  CONFIGURATION ERROR: SSL is enabled but ssl_mode is set to 'disable'!
        
        For production environments with SSL, use:
          use_ssl  = true
          ssl_mode = "require"  # or "verify-ca" or "verify-full"
        
        For development/testing without SSL:
          use_ssl  = false
          ssl_mode = "disable"
      EOT
    }
  }
}

# Validation 5: Port number validation
resource "terraform_data" "validate_port" {
  lifecycle {
    precondition {
      condition     = var.db_port > 0 && var.db_port <= 65535
      error_message = <<-EOT
        ❌ ERROR: Invalid port number!
        
        Port must be between 1 and 65535.
        Standard PostgreSQL port is 5432.
        
        Update terraform.tfvars:
          db_port = 5432
      EOT
    }
  }
}

# Validation 6: Hostname format validation
resource "terraform_data" "validate_hostname" {
  lifecycle {
    precondition {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.db_host))
      error_message = <<-EOT
        ❌ ERROR: Invalid hostname format!
        
        Hostname must:
          ✓ Start and end with alphanumeric characters
          ✓ Contain only letters, numbers, dots, and hyphens
          ✓ Not start or end with a dot or hyphen
        
        Examples:
          ✓ api.rr1.cp.fyre.ibm.com
          ✓ postgres-server.example.com
          ✓ 192.168.1.100
          ✗ -invalid.com
          ✗ invalid-.com
      EOT
    }
  }
}

#------------------------------------------------------------------------------
# PostgreSQL User Creation and Configuration
#------------------------------------------------------------------------------

# Create sqlguard user and gdmmonitor group for Guardium VA
resource "null_resource" "create_sqlguard_user" {
  # Ensure validations pass before creating user
  depends_on = [
    terraform_data.validate_admin_user,
    terraform_data.validate_sqlguard_password,
    terraform_data.validate_user_separation,
    terraform_data.validate_ssl_config,
    terraform_data.validate_port,
    terraform_data.validate_hostname
  ]

  provisioner "local-exec" {
    command = <<-EOT
      PGPASSWORD='${var.db_password}' ${var.use_ssl ? "PGSSLMODE=prefer" : "PGSSLMODE=disable"} PGCONNECT_TIMEOUT=30 psql \
        -h ${var.db_host} \
        -p ${var.db_port} \
        -U ${var.db_username} \
        -d ${var.db_name} \
        -c "
          -- Create sqlguard user if it doesn't exist
          DO \$\$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${var.sqlguard_username}') THEN
              CREATE ROLE ${var.sqlguard_username} LOGIN
              ENCRYPTED PASSWORD '${var.sqlguard_password}'
              NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
              RAISE NOTICE 'User ${var.sqlguard_username} created successfully';
            ELSE
              RAISE NOTICE 'User ${var.sqlguard_username} already exists';
            END IF;
          END
          \$\$;
          
          -- Create gdmmonitor group if it doesn't exist
          DO \$\$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'gdmmonitor') THEN
              CREATE GROUP gdmmonitor;
              RAISE NOTICE 'Group gdmmonitor created successfully';
            ELSE
              RAISE NOTICE 'Group gdmmonitor already exists';
            END IF;
          END
          \$\$;
          
          -- Add sqlguard to gdmmonitor group
          ALTER GROUP gdmmonitor ADD USER ${var.sqlguard_username};
          
          -- Grant required permissions for VA
          GRANT pg_read_all_settings TO gdmmonitor;
          
          -- Grant CONNECT permission on database
          GRANT CONNECT ON DATABASE ${var.db_name} TO ${var.sqlguard_username};
        "
    EOT

    on_failure = continue
  }

  # Verify user creation
  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying sqlguard user creation..."
      PGPASSWORD='${var.db_password}' ${var.use_ssl ? "PGSSLMODE=${var.ssl_mode}" : ""} psql \
        -h ${var.db_host} \
        -p ${var.db_port} \
        -U ${var.db_username} \
        -d ${var.db_name} \
        -c "SELECT rolname, rolsuper, rolinherit, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname IN ('${var.sqlguard_username}', 'gdmmonitor');"
    EOT

    on_failure = continue
  }

  # Test connection with sqlguard user
  provisioner "local-exec" {
    command = <<-EOT
      echo "Testing connection with sqlguard user..."
      PGPASSWORD='${var.sqlguard_password}' ${var.use_ssl ? "PGSSLMODE=${var.ssl_mode}" : ""} psql \
        -h ${var.db_host} \
        -p ${var.db_port} \
        -U ${var.sqlguard_username} \
        -d ${var.db_name} \
        -c "SELECT version();" || echo "⚠️  Warning: Could not connect with sqlguard user. Check permissions."
    EOT

    on_failure = continue
  }
}

#------------------------------------------------------------------------------
# Datasource Configuration for Guardium
#------------------------------------------------------------------------------

locals {
  # Build the datasource configuration for Guardium
  postgresql_datasource_config = templatefile("${path.module}/templates/postgresql_datasource.tpl", {
    datasource_name                 = var.datasource_name
    datasource_hostname             = var.db_host
    datasource_port                 = var.db_port
    db_name                         = var.db_name
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
# Connect the PostgreSQL database to Guardium Data Protection (GDP)
#------------------------------------------------------------------------------
# This resource registers the on-premise PostgreSQL database with Guardium
# and configures vulnerability assessment
module "postgresql_gdp_connection" {
  count  = var.enable_vulnerability_assessment ? 1 : 0
  source = "IBM/gdp/guardium//modules/connect-datasource-to-va"

  datasource_payload = local.postgresql_datasource_config

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