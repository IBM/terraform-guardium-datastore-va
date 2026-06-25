#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Couchbase Capella VA Config Module - Outputs

output "lambda_function_name" {
  description = "Name of the Lambda function used for VA configuration"
  value       = aws_lambda_function.va_config_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function used for VA configuration"
  value       = aws_lambda_function.va_config_lambda.arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing Couchbase Capella credentials"
  value       = aws_secretsmanager_secret.couchbase_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret containing Couchbase Capella credentials"
  value       = aws_secretsmanager_secret.couchbase_credentials.name
}

output "lambda_security_group_id" {
  description = "ID of the security group attached to the Lambda function"
  value       = aws_security_group.lambda_sg.id
}

output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint for Secrets Manager"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "guardium_datasource_config" {
  description = "Configuration for Guardium datasource (sensitive)"
  value = {
    datasource_type   = "Couchbase Capella"
    cluster_endpoint  = var.cluster_endpoint
    rest_api_endpoint = var.rest_api_endpoint
    port              = var.cluster_port
    bucket_name       = var.bucket_name
    tls_enabled       = true
    secret_arn        = aws_secretsmanager_secret.couchbase_credentials.arn
  }
  sensitive = true
}
