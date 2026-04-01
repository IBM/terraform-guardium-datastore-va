#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Azure Cosmos DB VA Config Module Variables

variable "cosmos_account_name" {
  description = "Name of the Azure Cosmos DB account"
  type        = string
}

variable "cosmos_account_endpoint" {
  description = "Endpoint URL of the Azure Cosmos DB account"
  type        = string
}

variable "cosmos_db_kind" {
  description = "Cosmos DB API kind (GlobalDocumentDB for SQL API, MongoDB for MongoDB API)"
  type        = string
  validation {
    condition     = contains(["GlobalDocumentDB", "MongoDB"], var.cosmos_db_kind)
    error_message = "cosmos_db_kind must be either 'GlobalDocumentDB' (SQL API) or 'MongoDB'"
  }
}

variable "database_name" {
  description = "Name of the Cosmos DB database"
  type        = string
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
  description = "Name of the existing VNet where Cosmos DB is deployed"
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

variable "guardium_ip_address" {
  description = "IP address of Guardium server for firewall rules (CIDR format, e.g., 1.2.3.4/32). Required only if enable_public_access = true"
  type        = string
  default     = ""
}

variable "enable_public_access" {
  description = "Enable public network access firewall rules. Set to false for production (use Private Link/VPN instead)"
  type        = bool
  default     = false
}

variable "additional_firewall_ips" {
  description = "Additional IP addresses to allow access (CIDR format). List of IP ranges to add to Cosmos DB firewall"
  type        = list(string)
  default     = []
}