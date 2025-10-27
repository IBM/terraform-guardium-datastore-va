# AWS RDS PostgreSQL with VA Example - Provider Configuration

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Uncomment the lines below to use AWS profiles or assume roles
  # profile = "your-profile-name"
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  # }

  # Default tags to apply to all resources
  default_tags {
    tags = var.tags
  }
}

# If you need to use multiple AWS regions, define additional provider configurations
# provider "aws" {
#   alias  = "us-west-2"
#   region = "us-west-2"
# }