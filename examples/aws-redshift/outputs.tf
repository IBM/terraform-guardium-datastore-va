# AWS Redshift with VA Example - Outputs

#------------------------------------------------------------------------------
# Redshift Cluster Outputs
#------------------------------------------------------------------------------

output "redshift_endpoint" {
  description = "The endpoint of the Redshift cluster"
  value       = local.redshift_endpoint
}

output "redshift_port" {
  description = "The port of the Redshift cluster"
  value       = local.redshift_port
}

output "redshift_database_name" {
  description = "The name of the Redshift database"
  value       = local.redshift_database_name
}

output "redshift_master_username" {
  description = "The master username for the Redshift database"
  value       = local.redshift_master_username
}

output "redshift_connection_string" {
  description = "JDBC connection string for the Redshift cluster"
  value       = "jdbc:redshift://${local.redshift_endpoint}/${local.redshift_database_name}"
  sensitive   = true
}

#------------------------------------------------------------------------------
# Network Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = data.aws_redshift_cluster.existing.vpc_id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = data.aws_redshift_cluster.existing.vpc_security_group_ids[0]
}

#------------------------------------------------------------------------------
# Vulnerability Assessment Outputs
#------------------------------------------------------------------------------

output "sqlguard_username" {
  description = "The username for the Guardium VA user"
  value       = var.sqlguard_username
}

output "datasource_name" {
  description = "The name of the datasource registered in Guardium"
  value       = var.datasource_name
}

output "assessment_schedule" {
  description = "The schedule for vulnerability assessments"
  value       = var.enable_vulnerability_assessment ? "${var.assessment_schedule} at ${var.assessment_time} on ${var.assessment_day}" : "Disabled"
}

#------------------------------------------------------------------------------
# Connection Instructions
#------------------------------------------------------------------------------

output "connection_instructions" {
  description = "Instructions for connecting to the Redshift cluster"
  value       = <<-EOT
    To connect to your existing Redshift cluster using psql:
    
    1. Connection details for your Redshift cluster:
       HOST=${local.redshift_hostname}
       PORT=${local.redshift_port}
       DB_NAME=${local.redshift_database_name}
       DB_USER=${local.redshift_master_username}
    
    2. Connect using psql (replace "your_secure_password" with your actual password):
       export PGPASSWORD="your_secure_password"
       psql -h ${local.redshift_hostname} -p ${local.redshift_port} -d ${local.redshift_database_name} -U ${local.redshift_master_username}
    
    3. To verify the VA configuration:
       psql -h ${local.redshift_hostname} -p ${local.redshift_port} -d ${local.redshift_database_name} -U ${local.redshift_master_username} -c "SELECT * FROM pg_user_info WHERE usename = '${var.sqlguard_username}';"
       psql -h ${local.redshift_hostname} -p ${local.redshift_port} -d ${local.redshift_database_name} -U ${local.redshift_master_username} -c "SELECT groname, grosysid FROM pg_group WHERE groname = 'gdmmonitor';"
  EOT
}