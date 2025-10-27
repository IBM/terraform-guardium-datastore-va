terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    local = {
      source = "hashicorp/local"
    }
    gdp-middleware-helper  = {
      source = "IBM/gdp-middleware-helper"
      version = ">= 1.0.0"
    }
  }
}
