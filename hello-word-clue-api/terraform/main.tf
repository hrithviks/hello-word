/*
Author      : Hrithvik Saseendran
Description : Main Configuration for Clue API
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

# Get Account Details
data "aws_caller_identity" "aws_resource_admin" {}

# Local variables
locals {
  resource_name_prefix                     = lower("${var.project_name}-${var.service_name}")
  aws_account_id                           = data.aws_caller_identity.aws_resource_admin.account_id
  api_gateway_lambda_permission_source_arn = "arn:aws:execute-api:${var.aws_region}:${local.aws_account_id}:${module.clue_api_rest_api.rest_api_id}/*/*"
}

/*
DYNAMODB RESOURCES

1. Dynamodb Table For Storing Clue Data
2. IAM Policy For Table Access
*/

# Invoke Dynamodb Table Module To Create A New Table
module "clue_api_table" {
  source = "../../terraform-modules/dynamo-db"

  # Assign values for module variables from input
  table_name     = lower("${local.resource_name_prefix}-db-${var.environment}")
  hash_key       = var.dynamodb_table_hash_key
  range_key      = var.dynamodb_table_range_key
  attributes     = var.dynamodb_table_attributes
  read_capacity  = var.dynamodb_table_rcu
  write_capacity = var.dynamodb_table_wcu

  tags = var.project_tags
}

# Generate Read-Only Access Policy For Dynamodb Table
module "clue_api_table_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = lower("${local.resource_name_prefix}-DynamoDB-ReadAccess-Policy-${var.environment}")
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
          module.clue_api_table.table_arn,
          "${module.clue_api_table.table_arn}/index/*" # For GSIs and LSIs
        ]
      },
    ]
  })

  iam_policy_tags = var.project_tags
}

/*
CLOUDWATCH RESOURCES

1. Cloudwatch Log Group For Lambda Function
2. Cloudwatch Log Group For Api Gateway
*/

# Create Cloudwatch Log Group For Lambda Function
module "clue_api_lambda_cloudwatch_log_group" {
  source = "../../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = lower("/aws/lambda/${local.resource_name_prefix}-func-${var.environment}")
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group for Lambda function
module "clue_api_lambda_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = lower("${local.resource_name_prefix}-Lambda-CloudWatch-Access-Policy-${var.environment}")
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
        Resource = "${module.clue_api_lambda_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}

# Create Cloudwatch Log Group For Api Gateway 
module "clue_api_api_gateway_cloudwatch_log_group" {
  source = "../../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = lower("${local.resource_name_prefix}/${var.environment}/api-gateway-logs")
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

# Create Policy For Read-Write Access To Cloudwatch Log Group For Api Gateway
module "clue_api_api_gateway_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = lower("${local.resource_name_prefix}-API-Gateway-CloudWatch-Access-Policy-${var.environment}")
  iam_policy_description = "IAM policy for granting access to CloudWatch log group for the API Gateway"
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
        Resource = "${module.clue_api_api_gateway_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}

/*
LAMBDA FUNCTION RESOURCES

1. IAM Execution Role For Lambda Service
2. Dynamo Db Access Policy Attachment For Lambda Exec Role
3. Cloudwatch Access Policy Attachment For Lambda Exec Role
4. Lambda Function To Generate Random Word
*/

# IAM Execution Role For Lambda Function
module "clue_api_lambda_exec_role" {
  source = "../../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = lower("${local.resource_name_prefix}-lambda-exec-role-${var.environment}")
  iam_role_description = "IAM role for lambda function to access other services"

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

# Attach The Dynamodb Access Policy To Game Word Table Role
resource "aws_iam_role_policy_attachment" "game_word_lambda_table_access_attachment" {
  role       = module.clue_api_lambda_exec_role.iam_role_name
  policy_arn = module.clue_api_table_access_policy.iam_policy_arn
}

# Attach Cloudwatch Access Policy To Execution Role For Lambda Function
resource "aws_iam_role_policy_attachment" "game_word_lambda_cloudwatch_access_attachment" {
  role       = module.clue_api_lambda_exec_role.iam_role_name
  policy_arn = module.clue_api_lambda_cloudwatch_access_policy.iam_policy_arn
}

# Create Lambda Function Using The Module And Attach IAM Role For Execution
module "clue_api_randomize_lambda" {
  source = "../../terraform-modules/lambda"

  lambda_function_name      = lower("${local.resource_name_prefix}-func-${var.environment}")
  lambda_handler            = "${var.python_source_code_file_name}.${var.python_function_name}"
  lambda_runtime            = "python${var.python_version_num}"
  lambda_memory_size        = var.python_exec_memory_size
  lambda_timeout            = var.python_exec_timeout
  lambda_iam_role_arn       = module.clue_api_lambda_exec_role.iam_role_arn
  lambda_s3_bucket_for_code = var.python_s3_bucket
  lambda_s3_key_for_code    = var.python_s3_key
  lambda_environment_variables = merge(var.python_env_vars, {
    DYNAMODB_TABLE_NAME = module.clue_api_table.table_name
  })
  lambda_tags = var.project_tags

  depends_on = [
    module.clue_api_lambda_cloudwatch_log_group,
    aws_iam_role_policy_attachment.game_word_lambda_cloudwatch_access_attachment
  ]
}

/*
API GATEWAY RESOURCES

1. IAM Execution Role For Api Gateway Service
2. Cloudwatch Access Policy Attachment For Api Gateway Exec Role
3. Api Gateway Resource
4. Lambda Permission For Api Gateway Invocation
*/

# IAM Execution Role For Api Gateway
module "clue_api_api_gateway_exec_role" {
  source = "../../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = lower("${local.resource_name_prefix}-api-gateway-exec-role-${var.environment}")
  iam_role_description = "IAM role for API Gateway to access other services"

  # Assume Role Policy for a Lambda Function
  iam_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  iam_role_tags = var.project_tags
}

# Attach The Cloudwatch Access Policy To IAM Role For Api Gateway
resource "aws_iam_role_policy_attachment" "game_word_api_gateway_cloudwatch_access_attachment" {
  role       = module.clue_api_api_gateway_exec_role.iam_role_name
  policy_arn = module.clue_api_api_gateway_cloudwatch_access_policy.iam_policy_arn
}

# Create the API Gateway Resource
module "clue_api_rest_api" {
  source                           = "../../terraform-modules/api-gateway/rest_api/"
  api_gateway_name                 = "random-word-api-dev"
  api_gateway_description          = "API to retrieve random word via lambda function"
  api_gateway_rest_endpoint_config = "REGIONAL"
  api_gateway_rest_api_body        = jsonencode(local.random_word_openapi_specification_map)
}

# Add Lambda Permission For The Api Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.clue_api_randomize_lambda.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = local.api_gateway_lambda_permission_source_arn

  # Add explicit dependency on API Gateway and Lambda resource
  depends_on = [
    module.clue_api_rest_api,
    module.clue_api_randomize_lambda
  ]
}

/*
OUTPUTS SECTION
*/

# Output The Dynamodb Table Name And Arn
output "clue_api_table_name" {
  description = "The name of the created DynamoDB table"
  value       = module.clue_api_table.table_name
}

output "clue_api_table_arn" {
  description = "The ARN of the created DynamoDB table"
  value       = module.clue_api_table.table_arn
}

# Output Details Of Cloudwatch Log Group
output "cloudwatch_log_group_arn" {
  description = "The ARN of the created CloudWatch log group"
  value       = module.clue_api_lambda_cloudwatch_log_group.log_group_arn
}

# Output Arn Of Lambda Function
output "lambda_function_arn" {
  description = "The ARN of the created lambda function"
  value       = module.clue_api_randomize_lambda.lambda_arn
}
