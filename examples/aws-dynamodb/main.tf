# AWS DynamoDB with Vulnerability Assessment Example

#----------------------------------------
# No Provider Configuration Here
# Providers are configured in provider.tf
#----------------------------------------

# Local variables for payload processing
locals {
  # Generate a secret name with a prefix based on the datasource name
  secret_name = "${var.dynamodb_datasource_name}-dynamo-credentials"
  
  dynamodb_config_tpl = templatefile("${path.module}/../../modules/datastore-va-config/aws-dynamodb/templates/dynamodb_datasource.tpl", {
    datasource_name = var.dynamodb_datasource_name
    datasource_hostname = "dynamodb.${var.aws_region}.amazonaws.com"
    datasource_port = 5432
    application = "Security Assessment"
    datasource_description = var.dynamodb_description
    datasource_database = "default"
    severity_level = "MED"
    use_ssl = false
    import_server_ssl_cert = false
    use_kerberos = false
    use_ldap = false
    external_password_type_name = "AWS SECRETS MANAGER"
    aws_secrets_manager_config_name = var.aws_secrets_manager_name
    region = var.aws_secrets_manager_region
    secret_name = var.aws_secrets_manager_secret != null ? var.aws_secrets_manager_secret : local.secret_name
  })
  dynamodb_config_json_decoded = jsondecode(local.dynamodb_config_tpl)
  dynamodb_config_json_encoded = jsonencode(local.dynamodb_config_json_decoded)
}

#----------------------------------------
# DynamoDB Vulnerability Assessment Configuration
#----------------------------------------
module "dynamodb_va" {
  source = "../../modules/datastore-va-config/aws-dynamodb"

  # IAM Configuration
  iam_role_name        = "guardium-dynamodb-va-role-${var.dynamodb_datasource_name}"
  iam_policy_name      = "guardium-dynamodb-va-policy-${var.dynamodb_datasource_name}"
  iam_role_description = "IAM role for Guardium vulnerability assessment of DynamoDB"
  # Tags
  tags = var.tags
}

#----------------------------------------
# Connect DynamoDB to Guardium Data Protection
#----------------------------------------
module "dynamodb_gdp_connection" {
  source = "../../modules/vulnerability-assessment/connect-datasource-to-gdp"

  #----------------------------------------
  # Guardium Connection Details
  #----------------------------------------
  gdp_server            = var.gdp_server
  gdp_port              = var.gdp_port
  gdp_username          = var.guardium_username
  gdp_password          = var.guardium_password
  client_id             = var.client_id
  client_secret         = var.client_secret
  
  #----------------------------------------
  # Datasource Information
  #----------------------------------------
  datasource_name        = var.dynamodb_datasource_name
  
  # Use the encoded JSON payload
  datasource_payload = "${local.dynamodb_config_json_encoded}"
  
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
  enable_notifications  = false
  notification_emails   = []
  notification_severity = "HIGH"
  
  # Tags
  tags = var.tags
  
  # Dependencies
  depends_on = [module.dynamodb_va]
}
