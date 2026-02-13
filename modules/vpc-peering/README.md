# VPC Peering Module for Guardium Database Connectivity

This module creates VPC peering connections between Guardium VPC and Database VPCs, enabling cross-VPC connectivity for databases that require it.

## Overview

This module automates the VPC peering setup process by:
- Creating VPC peering connection between two VPCs
- Automatically accepting the peering connection (if in same account)
- **Automatically discovering CIDR blocks from VPC IDs**
- **Automatically discovering all route tables in both VPCs**
- Adding routes in all route tables to enable bidirectional traffic

## When to Use This Module

Use this module when:
- Your database is in a **different VPC** from Guardium
- The database requires **private connectivity** (no public endpoint)
- You need to establish **network routing** between VPCs

**Examples:**
- DocumentDB in VPC-A, Guardium in VPC-B
- RDS MySQL in VPC-A, Guardium in VPC-B (if using private endpoints)
- Any database requiring cross-VPC private connectivity

## Usage

### Basic Example

```terraform
module "vpc_peering" {
  source = "../../modules/vpc-peering"

  enable_vpc_peering = true

  # Only VPC IDs needed - everything else is auto-discovered!
  requester_vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Guardium VPC
  accepter_vpc_id  = "vpc-yyyyyyyyyyyyyyyyy"  # Database VPC

  peering_connection_name = "guardium-to-documentdb"

  tags = {
    Environment = "production"
    Purpose     = "guardium-connectivity"
  }
}
```

### With DocumentDB Example

```terraform
# Step 1: Create VPC Peering (optional)
module "vpc_peering" {
  source = "../../modules/vpc-peering"

  enable_vpc_peering = var.enable_vpc_peering

  requester_vpc_id = var.guardium_vpc_id
  accepter_vpc_id  = var.documentdb_vpc_id

  peering_connection_name = "guardium-to-documentdb"
  tags                    = var.tags
}

# Step 2: Create DocumentDB VA Configuration
module "documentdb_va" {
  source = "../../modules/aws-rds-documentdb"
  
  # ... DocumentDB configuration
  
  depends_on = [module.vpc_peering]
}
```

## Automatic Discovery

The module automatically discovers:
- ✅ **CIDR blocks** for both VPCs
- ✅ **All route tables** in both VPCs
- ✅ Creates routes in **all discovered route tables**

You only need to provide the VPC IDs!

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_vpc_peering | Enable VPC peering between Guardium VPC and Database VPC | `bool` | `false` | no |
| requester_vpc_id | VPC ID of the requester (typically Guardium VPC) | `string` | n/a | yes |
| accepter_vpc_id | VPC ID of the accepter (typically Database VPC) | `string` | n/a | yes |
| auto_accept | Automatically accept the peering connection | `bool` | `true` | no |
| peering_connection_name | Name tag for the VPC peering connection | `string` | `"guardium-to-database-peering"` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_peering_connection_id | ID of the VPC peering connection |
| vpc_peering_connection_status | Status of the VPC peering connection |
| requester_routes_created | Number of routes created in requester VPC |
| accepter_routes_created | Number of routes created in accepter VPC |

## Features

- ✅ Automatic VPC peering connection creation
- ✅ Auto-accept for same-account peering
- ✅ **Automatic CIDR block discovery**
- ✅ **Automatic route table discovery**
- ✅ Automatic route creation in all route tables
- ✅ Conditional creation (enable/disable via variable)
- ✅ Comprehensive tagging support

## How It Works

1. **Data Sources**: Module uses Terraform data sources to query AWS:
   ```terraform
   data "aws_vpc" "requester" {
     id = var.requester_vpc_id
   }
   
   data "aws_route_tables" "requester" {
     vpc_id = var.requester_vpc_id
   }
   ```

2. **Automatic Discovery**: Fetches CIDR blocks and route table IDs automatically

3. **Route Creation**: Creates routes in all discovered route tables

## Notes

- Both VPCs must be in the same AWS account for `auto_accept = true`
- Ensure CIDR blocks don't overlap between VPCs
- Security groups must still allow traffic between VPCs
- VPC peering is not transitive (A-B and B-C doesn't mean A-C)
- All route tables in both VPCs will get peering routes

## Cleanup

To destroy the VPC peering:

```bash
terraform destroy -target=module.vpc_peering
```

Or set `enable_vpc_peering = false` and run `terraform apply`.