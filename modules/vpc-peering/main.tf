#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# Generic VPC Peering Module for Guardium Database Connectivity

#------------------------------------------------------------------------------
# Data Sources - Automatically fetch VPC details
#------------------------------------------------------------------------------
data "aws_vpc" "requester" {
  count = var.enable_vpc_peering ? 1 : 0
  id    = var.requester_vpc_id
}

data "aws_vpc" "accepter" {
  count = var.enable_vpc_peering ? 1 : 0
  id    = var.accepter_vpc_id
}

data "aws_route_tables" "requester" {
  count  = var.enable_vpc_peering ? 1 : 0
  vpc_id = var.requester_vpc_id
}

data "aws_route_tables" "accepter" {
  count  = var.enable_vpc_peering ? 1 : 0
  vpc_id = var.accepter_vpc_id
}

#------------------------------------------------------------------------------
# VPC Peering Connection
#------------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "this" {
  count = var.enable_vpc_peering ? 1 : 0

  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = var.auto_accept

  tags = merge(
    var.tags,
    {
      Name = var.peering_connection_name
    }
  )
}

#------------------------------------------------------------------------------
# Accept VPC Peering Connection (if not auto-accepted)
#------------------------------------------------------------------------------
resource "aws_vpc_peering_connection_accepter" "this" {
  count = var.enable_vpc_peering && !var.auto_accept ? 1 : 0

  vpc_peering_connection_id = aws_vpc_peering_connection.this[0].id
  auto_accept               = true

  tags = merge(
    var.tags,
    {
      Name = "${var.peering_connection_name}-accepter"
    }
  )
}

#------------------------------------------------------------------------------
# Routes in Requester VPC (Guardium VPC)
#------------------------------------------------------------------------------
resource "aws_route" "requester_to_accepter" {
  for_each = var.enable_vpc_peering ? toset(data.aws_route_tables.requester[0].ids) : toset([])

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.accepter[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this[0].id
}

#------------------------------------------------------------------------------
# Routes in Accepter VPC (Database VPC)
#------------------------------------------------------------------------------
resource "aws_route" "accepter_to_requester" {
  for_each = var.enable_vpc_peering ? toset(data.aws_route_tables.accepter[0].ids) : toset([])

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.requester[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this[0].id
}