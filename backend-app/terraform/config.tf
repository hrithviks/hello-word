# Setup Terraform Configuration
terraform {

  # Backend
  backend "s3" {
    bucket  = "hello-word-game"
    key     = "backend-app/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }

  # Providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0"
    }
  }
  required_version = ">=1.12.0"
}
