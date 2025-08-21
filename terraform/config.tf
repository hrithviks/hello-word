################################################
# Backend and providers for main configuration #
################################################

terraform {

  backend "s3" {
    bucket  = "hello-word-game"
    key     = "terraform/main-config.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0.0"
    }
  }

  required_version = "~>1.12"
}
