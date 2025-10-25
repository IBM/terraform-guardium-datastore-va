terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    guardium-data-protection = {
      source = "na.artifactory.swg-devops.com/ibm/guardium-data-protection"
      version = "0.0.4"
    }
    gdp-middleware-helper  = {
      source = "na.artifactory.swg-devops.com/ibm/gdp-middleware-helper"
      version = "0.0.3"
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

# The guardium-data-protection provider uses environment variables for authentication:
# GUARDIUM_USERNAME, GUARDIUM_PASSWORD, GUARDIUM_HOST, GUARDIUM_PORT,
# GUARDIUM_CLIENT_ID, GUARDIUM_CLIENT_SECRET
provider "guardium-data-protection" {
  host = var.gdp_server
  port = var.gdp_port
}

# To use this custom provider, you need to configure Terraform to access the private registry:
# 1. Create a ~/.terraformrc file with the following content:
#    provider_installation {
#      network_mirror {
#        url = "https://na.artifactory.swg-devops.com/artifactory/api/terraform/sec-guardium-next-gen-terraform-local/providers/"
#        include = ["na.artifactory.swg-devops.com/*/*"]
#      }
#      direct {
#        exclude = ["na.artifactory.swg-devops.com/*/*"]
#      }
#    }
#
#    credentials "na.artifactory.swg-devops.com" {
#      token = "YOUR_ARTIFACTORY_API_TOKEN"
#    }
#
# 2. Set the GUARDIUM_* environment variables for provider authentication:
#    export GUARDIUM_USERNAME="your_username"
#    export GUARDIUM_PASSWORD="your_password"
#    export GUARDIUM_HOST="guardium.example.com"
#    export GUARDIUM_PORT="8443"
#    export GUARDIUM_CLIENT_ID="client1"
#    export GUARDIUM_CLIENT_SECRET="your_client_secret"