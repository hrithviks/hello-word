/*
Author      : Hrithvik Saseendran
Description : Main Configuration for Guess Word API
*/

# Setup Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0"
    }
  }
  required_version = ">=1.12.0"
}

# Setup Region
provider "aws" {
  region = var.aws_region
}


# Invoke DynamoDB Table Module
module "game_words_table" {
  source = "./modules/dynamo-db"

  # Assign values for module variables from input
  table_name     = "${var.project_name}-${upper(var.environment)}"
  hash_key       = var.dynamodb_table_hash_key
  range_key      = var.dynamodb_table_range_key
  attributes     = var.dynamodb_table_attributes
  read_capacity  = var.dynamodb_table_rcu
  write_capacity = var.dynamodb_table_wcu

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "GameWords"
    Terraform   = true
  }
}

# Output the table name and ARN for use in CI/CD or other modules
output "game_words_table_name" {
  description = "The name of the created DynamoDB table."
  value       = module.game_words_table.table_name
}

output "game_words_table_arn" {
  description = "The ARN of the created DynamoDB table."
  value       = module.game_words_table.table_arn
}
