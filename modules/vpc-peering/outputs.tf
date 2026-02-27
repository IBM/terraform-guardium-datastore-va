#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Generic VPC Peering Module Outputs

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = var.enable_vpc_peering ? aws_vpc_peering_connection.this[0].id : null
}

output "vpc_peering_connection_status" {
  description = "Status of the VPC peering connection"
  value       = var.enable_vpc_peering ? aws_vpc_peering_connection.this[0].accept_status : null
}

output "requester_routes_created" {
  description = "Number of routes created in requester VPC"
  value       = var.enable_vpc_peering ? length(aws_route.requester_to_accepter) : 0
}

output "accepter_routes_created" {
  description = "Number of routes created in accepter VPC"
  value       = var.enable_vpc_peering ? length(aws_route.accepter_to_requester) : 0
}