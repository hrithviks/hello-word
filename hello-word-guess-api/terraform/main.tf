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
  table_name     = "${var.service_name}-${upper(var.environment)}"
  hash_key       = var.dynamodb_table_hash_key
  range_key      = var.dynamodb_table_range_key
  attributes     = var.dynamodb_table_attributes
  read_capacity  = var.dynamodb_table_rcu
  write_capacity = var.dynamodb_table_wcu

  tags = var.project_tags
}

# Invoke IAM Roles Module to create a role for DynamoDB backend
module "game_words_table_access_role" {
  source = "./modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${var.service_name}-${upper(var.environment)}-DynamoDB-Access-Role"
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

  iam_role_tags = var.project_tags
}

# Generate read-only access policy for DynamoDB table
module "game_words_table_access_policy" {
  source = "./modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = "${var.service_name}-${upper(var.environment)}-DynamoDB-ReadAccess-Policy"
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

  iam_policy_tags = var.project_tags
}

# Attach the DynamoDB access policy to game word table role
resource "aws_iam_role_policy_attachment" "game_word_table_access_attachment" {
  role       = module.game_words_table_access_role.iam_role_name
  policy_arn = module.game_words_table_access_policy.iam_policy_arn
}

# Create Cloudwatch log group
module "game_words_lambda_cloudwatch_log_group" {
  source = "./modules/cloudwatch/"

  cloudwatch_log_group_name    = "/${lower(var.project_name)}/${var.environment}/lambda/loggroup-${lower(var.service_name)}"
  cloudwatch_retention_in_days = 30 # Example retention policy
  cloudwatch_tags              = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group

# Attach Cloudwatch access policy to execution role for lambda function

# Create Lambda function using the module and attach IAM role for execution

# Output the table name and ARN for use in CI/CD or other modules
output "game_words_table_name" {
  description = "The name of the created DynamoDB table."
  value       = module.game_words_table.table_name
}

output "game_words_table_arn" {
  description = "The ARN of the created DynamoDB table."
  value       = module.game_words_table.table_arn
}

# Output details of Lambda function
