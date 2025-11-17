terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    guardium-data-protection = {
      source  = "ibm/guardium-data-protection"
      version = ">= 1.0.0"
    }
    gdp-middleware-helper = {
      source  = "ibm/gdp-middleware-helper"
      version = ">= 1.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "guardium-data-protection" {
  host = var.gdp_server
  port = var.gdp_port
}