#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure MySQL VA Config Module Variables

variable "db_host" {
  description = "Hostname or FQDN of the Azure MySQL Flexible Server"
  type        = string
}

variable "db_port" {
  description = "Port for the Azure MySQL server"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Name of the Azure MySQL database"
  type        = string
}

variable "db_username" {
  description = "Username for the Azure MySQL database (must have admin privileges)"
  type        = string
}

variable "db_password" {
  description = "Password for the Azure MySQL database"
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

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Purpose = "guardium-va-config"
    Owner   = "your-email@example.com"
  }
}

variable "name_prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "vnet_name" {
  description = "Name of the existing VNet where MySQL server is deployed"
  type        = string
}

variable "function_subnet_address_prefix" {
  description = "Address prefix for the Function App subnet (e.g., 10.0.2.0/24)"
  type        = string
}

variable "guardium_hostname" {
  description = "Hostname or IP address of the Guardium server (will be resolved to IP for firewall rules). Required only if enable_public_access = true"
  type        = string
  default     = ""
}

variable "mysql_server_name" {
  description = "Name of the Azure MySQL Flexible Server (for adding firewall rules). Required only if enable_public_access = true"
  type        = string
  default     = ""
}

variable "enable_public_access" {
  description = "Enable public network access firewall rules. Set to false for production (use Private Link/VPN instead)"
  type        = bool
  default     = false
}

variable "additional_firewall_rules" {
  description = "Additional firewall rules to allow access from specific IP ranges. Map of rule names to objects with start_ip and end_ip"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}