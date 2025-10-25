terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    local = {
      source = "hashicorp/local"
    }
    gdp-middleware-helper  = {
      source = "na.artifactory.swg-devops.com/ibm/gdp-middleware-helper"
      version = "0.0.3"
    }
  }
}