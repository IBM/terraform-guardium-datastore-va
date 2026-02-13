#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Generic VPC Peering Module Variables

variable "enable_vpc_peering" {
  description = "Enable VPC peering between Guardium VPC and Database VPC"
  type        = bool
  default     = false
}

variable "requester_vpc_id" {
  description = "VPC ID of the requester (typically Guardium VPC). CIDR block and route tables will be automatically discovered."
  type        = string
}

variable "accepter_vpc_id" {
  description = "VPC ID of the accepter (typically Database VPC). CIDR block and route tables will be automatically discovered."
  type        = string
}

variable "auto_accept" {
  description = "Automatically accept the peering connection (both VPCs in same account)"
  type        = bool
  default     = true
}

variable "peering_connection_name" {
  description = "Name tag for the VPC peering connection"
  type        = string
  default     = "guardium-to-database-peering"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}