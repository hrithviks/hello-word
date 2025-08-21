# Terraform configuration for S3 backend
terraform {
  backend "s3" {
    bucket  = "hello-word-game"
    key     = "random-word-api/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
