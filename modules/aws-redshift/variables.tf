# Redshift VA Config Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "guardium"
}

variable "redshift_host" {
  description = "Hostname or IP address of the Redshift cluster"
  type        = string
}

variable "redshift_port" {
  description = "Port for the Redshift cluster"
  type        = number
  default     = 5439
}

variable "redshift_database" {
  description = "Name of the Redshift database"
  type        = string
}

variable "redshift_username" {
  description = "Username for the Redshift database (must have superuser privileges)"
  type        = string
}

variable "redshift_password" {
  description = "Password for the Redshift database"
  type        = string
  sensitive   = true
}

variable "sqlguard_password" {
  description = "Password for the sqlguard user"
  type        = string
  sensitive   = true
}

variable "sqlguard_username" {
  description = "Username for the Guardium user"
  type        = string
  default     = "sqlguard"
}

variable "vpc_id" {
  description = "ID of the VPC where the Lambda function will be created (optional, only needed if Redshift is in a private VPC)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of the subnet where the Lambda function will be created (optional, only needed if Redshift is in a private VPC)"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "allowed_egress_cidr_blocks" {
  description = "List of CIDR blocks allowed for outbound traffic from the Lambda function"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Default is open to all, but users can restrict this
}