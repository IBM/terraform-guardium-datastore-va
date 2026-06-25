#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure PostgreSQL VA Configuration Example - Variables

# Azure Infrastructure Variables
variable "resource_group_name" {
  description = "Name of the Azure resource group where PostgreSQL server is deployed"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "canadacentral"
}

variable "name_prefix" {
  description = "Prefix to use for resource names (must be unique)"
  type        = string
}

# PostgreSQL Database Variables
variable "postgresql_server_name" {
  description = "Name of the Azure PostgreSQL Flexible Server"
  type        = string
}

variable "db_host" {
  description = "Hostname or FQDN of the Azure PostgreSQL Flexible Server"
  type        = string
}

variable "db_port" {
  description = "Port for the Azure PostgreSQL server"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the PostgreSQL database"
  type        = string
}

variable "db_password" {
  description = "Admin password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

# VA User Configuration
variable "sqlguard_username" {
  description = "Username for the Guardium VA user"
  type        = string
  default     = "sqlguard"
}

variable "sqlguard_password" {
  description = "Password for the Guardium VA user"
  type        = string
  sensitive   = true
}

# VNet Configuration
variable "vnet_name" {
  description = "Name of the existing VNet where PostgreSQL server is deployed"
  type        = string
}

variable "function_subnet_address_prefix" {
  description = "Address prefix for the Function App subnet (e.g., 10.0.2.0/24)"
  type        = string
  default     = "10.0.2.0/24"
}

# Guardium Server Configuration
variable "guardium_hostname" {
  description = "Hostname or IP address of the Guardium server (will be resolved to IP for firewall rules)"
  type        = string
  default     = ""
}

variable "enable_public_access" {
  description = "Enable public network access firewall rules. Set to false for production (use Private Link/VPN instead)"
  type        = bool
  default     = false
}

variable "additional_firewall_rules" {
  description = "Additional firewall rules to allow access from specific IP ranges"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

# Guardium Data Protection (GDP) Connection Variables
variable "gdp_host" {
  description = "Hostname or IP address of the Guardium Data Protection server"
  type        = string
}

variable "gdp_port" {
  description = "Port for the Guardium Data Protection API"
  type        = number
  default     = 8443
}

variable "gdp_username" {
  description = "Username for Guardium Data Protection API authentication"
  type        = string
}

variable "gdp_password" {
  description = "Password for Guardium Data Protection API authentication"
  type        = string
  sensitive   = true
}

variable "gdp_api_token" {
  description = "API token for Guardium Data Protection (alternative to username/password)"
  type        = string
  default     = ""
  sensitive   = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Purpose     = "guardium-va-config"
    ManagedBy   = "terraform"
  }
}
