# Terraform configuration for back end

terraform {
  backend "s3" {
    bucket  = "hello-word-random-api"
    key     = "random-word-api-tf/dev.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
