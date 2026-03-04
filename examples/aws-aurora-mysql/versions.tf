#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    guardium-data-protection = {
      source = "IBM/guardium-data-protection"
    }
    gdp-middleware-helper = {
      source = "IBM/gdp-middleware-helper"
    }
  }
}