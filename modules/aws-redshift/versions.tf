terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    guardium-data-protection = {
      source = "IBM/guardium-data-protection"
      version = "0.0.4"
    }
    gdp-middleware-helper = {
      source = "IBM/gdp-middleware-helper"
      version = "1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
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

provider "aws" {
  region = var.aws_region
}


provider "guardium-data-protection" {
  host = var.gdp_server
  port = var.gdp_port
}
