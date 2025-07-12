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

# Invoke DynamoDB Table Module to create a new table
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

# Invoke IAM Roles Module to create a role for DynamoDB backend
module "game_words_table_access_role" {
  source = "./modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${var.project_name}-${upper(var.environment)}-DynamoDBAccess-Role"
  iam_role_description = "IAM role for the Hello Word game table on DynamodDB"

  # Assume Role Policy for a Lambda Function
  iam_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  iam_role_tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "GameWords"
    Terraform   = true
  }
}

module "game_words_table_access_policy" {
  source = "./modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = "${var.project_name}-${upper(var.environment)}-DynamoDB-ReadAccess-Policy"
  iam_policy_description = "IAM policy for granting access to DynamoDB table"

  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          module.game_words_table.table_arn,
          "${module.game_words_table.table_arn}/index/*" # For GSIs and LSIs
        ]
      },
    ]
  })

  iam_policy_tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "GameWords"
    Terraform   = true
  }
}

# Invoke IAM Policies Module to create and attach policy to DynamoDB table

# Output the table name and ARN for use in CI/CD or other modules
output "game_words_table_name" {
  description = "The name of the created DynamoDB table."
  value       = module.game_words_table.table_name
}

output "game_words_table_arn" {
  description = "The ARN of the created DynamoDB table."
  value       = module.game_words_table.table_arn
}
