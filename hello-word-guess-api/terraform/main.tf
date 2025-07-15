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

# Get account details
data "aws_caller_identity" "aws_resource_admin" {}

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
  iam_role_name        = "${var.service_name}-DynamoDB-Access-Role-${upper(var.environment)}"
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
  iam_policy_name        = "${var.service_name}-DynamoDB-ReadAccess-Policy-${upper(var.environment)}"
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

  cloudwatch_log_group_name    = "/aws/lambda/${var.project_name}-${var.service_name}-${upper(var.environment)}"
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group
module "game_words_cloudwatch_access_policy" {
  source = "./modules/iam/policies/"

  iam_policy_name        = "${var.service_name}-CloudWatch-Access-Policy-${upper(var.environment)}"
  iam_policy_description = "IAM policy for granting access to CloudWatch log group for the Lambda function"
  iam_policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.aws_resource_admin.account_id}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "${module.game_words_lambda_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}

# Attach Cloudwatch access policy to execution role for lambda function
resource "aws_iam_role_policy_attachment" "game_word_cloudwatch_access_attachment" {
  role       = module.game_words_table_access_role.iam_role_name
  policy_arn = module.game_words_cloudwatch_access_policy.iam_policy_arn
}

# Create Lambda function using the module and attach IAM role for execution
module "game_words_randomize_lambda" {
  source = "./modules/lambda"

  lambda_function_name      = "${var.project_name}-${var.service_name}-${upper(var.environment)}"
  lambda_handler            = "${var.python_source_code_file_name}.${var.python_function_name}"
  lambda_runtime            = "python${var.python_version_num}"
  lambda_memory_size        = var.python_exec_memory_size
  lambda_timeout            = var.python_exec_timeout
  lambda_iam_role_arn       = module.game_words_table_access_role.iam_role_arn
  lambda_s3_bucket_for_code = var.python_s3_bucket
  lambda_s3_key_for_code    = var.python_s3_key
  lambda_environment_variables = merge(var.python_env_vars, {
    DYNAMODB_TABLE_NAME = module.game_words_table.table_name
  })
  lambda_tags = var.project_tags

  depends_on = [
    module.game_words_lambda_cloudwatch_log_group,
    aws_iam_role_policy_attachment.game_word_cloudwatch_access_attachment
  ]
}

# Output the DynamoDB table name and ARN
output "game_words_table_name" {
  description = "The name of the created DynamoDB table"
  value       = module.game_words_table.table_name
}

output "game_words_table_arn" {
  description = "The ARN of the created DynamoDB table"
  value       = module.game_words_table.table_arn
}

# Output details of CloudWatch Log group
output "cloudwatch_log_group_arn" {
  description = "The ARN of the created CloudWatch log group"
  value       = module.game_words_lambda_cloudwatch_log_group.log_group_arn
}

# Output details of Lambda function
output "lambda_function_arn" {
  description = "The ARN of the created lambda function"
  value       = module.game_words_randomize_lambda.lambda_arn
}
