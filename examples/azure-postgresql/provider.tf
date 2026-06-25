#
# Copyright IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

provider "azurerm" {
  features {}
}

provider "guardium-data-protection" {
  host     = var.gdp_host
  port     = var.gdp_port
  username = var.gdp_username
  password = var.gdp_password
}
