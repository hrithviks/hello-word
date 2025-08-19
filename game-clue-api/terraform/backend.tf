# Terraform configuration for back end

terraform {
  backend "s3" {
    bucket  = "hello-word-clue-api"
    key     = "hello-word-api-state/dev.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
