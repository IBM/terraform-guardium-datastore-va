# RDS PostgreSQL VA Config Module Variables

variable "db_host" {
  description = "Hostname or IP address of the PostgreSQL database"
  type        = string
}

variable "db_port" {
  description = "Port for the PostgreSQL database"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the PostgreSQL database (must have superuser privileges)"
  type        = string
}

variable "db_password" {
  description = "Password for the PostgreSQL database"
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
  description = "ID of the VPC where the EC2 instance will be created"
  type        = string
}

variable "subnet_ids" {
  description = "list of IDs of the subnet where the EC2 instance will be created"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}