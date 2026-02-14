#
<<<<<<< HEAD
# Copyright IBM Corp. 2025
=======
# Copyright IBM Corp. 2026
>>>>>>> ea7b84d (feat: Add on-premise PostgreSQL VA module with full GDP integration (#22))
# SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    guardium-data-protection = {
      source  = "IBM/guardium-data-protection"
      version = ">= 1.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}

provider "guardium-data-protection" {
  host = var.gdp_server
  port = var.gdp_port
}