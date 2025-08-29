/*
Project     : Hello Word Game
Service     : Random Word API Service
Description : The terraform configuration for AWS resources for the Random Word API Service
*/

# Setup Region
provider "aws" {
  region = var.aws_region
}

# Get account details
data "aws_caller_identity" "aws_resource_admin" {}

# Get remote state of main configuration
data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "hello-word-game"
    key    = "terraform/main-config.tfstate"
    region = "ap-southeast-1"
  }
}

# Locals block to assign outputs from remote state
locals {

  # From remote state
  main_vpc_id                = data.terraform_remote_state.main.outputs.main_vpc_id
  main_prv_subnet_id         = data.terraform_remote_state.main.outputs.main_private_subnet_id
  main_prv_rt_id             = data.terraform_remote_state.main.outputs.main_private_rt_id
  main_pub_subnet_id         = data.terraform_remote_state.main.outputs.main_public_subnet_id
  main_pub_rt_id             = data.terraform_remote_state.main.outputs.main_public_rt_id
  main_lambda_exec_role_name = data.terraform_remote_state.main.outputs.main_lambda_exec_role_name
  main_lambda_exec_role_arn  = data.terraform_remote_state.main.outputs.main_lambda_exec_role_arn
  main_rest_api_name         = data.terraform_remote_state.main.outputs.main_api_gateway_name
  main_rest_api_id           = data.terraform_remote_state.main.outputs.main_api_gateway_id

  # Internal usage
  name_prefix    = lower("${var.project_name}-${var.service_name}")
  aws_account_id = data.aws_caller_identity.aws_resource_admin.account_id
}

######################
# DynamoDB Resources #
######################

# Invoke DynamoDB Table Module to create a new table
module "game_words_table" {
  source = "../../terraform-modules/dynamo-db"

  # Assign values for module variables from input
  table_name     = "${local.name_prefix}-db"
  hash_key       = var.dynamodb_table_hash_key
  range_key      = var.dynamodb_table_range_key
  attributes     = var.dynamodb_table_attributes
  read_capacity  = var.dynamodb_table_rcu
  write_capacity = var.dynamodb_table_wcu

  tags = var.project_tags
}

# Generate read-only access policy for DynamoDB table
module "game_words_table_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = "${local.name_prefix}-dynamodb-readaccess-policy"
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
      }
    ]
  })

  iam_policy_tags = var.project_tags
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "random_word_api_dynamodb_endpoint" {
  vpc_id       = local.main_vpc_id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [
    local.main_prv_rt_id,
    local.main_pub_rt_id
  ]
  tags = merge(var.project_tags, { Name = "DynamoDB VPC Gateway Endpoint" })
}

###################################
# CloudWatch Log Group for Lambda #
###################################

# Create Cloudwatch log group for Lambda function
module "game_words_lambda_cloudwatch_log_group" {
  source = "../../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = "/aws/lambda/${local.name_prefix}-func"
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group for Lambda function
module "game_words_lambda_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = "${local.name_prefix}-lambda-cloudwatch-access-policy"
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

#######################################
# Security Groups for Lambda Function #
#######################################

# Security group for private lambda functions
resource "aws_security_group" "random_word_api_lambda_sg" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for random word API lambda function"
  vpc_id      = local.main_vpc_id
}

# Security group rule for outbound connections from private lambda functions to dynamodb
resource "aws_security_group_rule" "random_word_api_lambda_sg_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.random_word_api_lambda_sg.id
  prefix_list_ids   = [aws_vpc_endpoint.random_word_api_dynamodb_endpoint.prefix_list_id]
  description       = "Allow outbound access to DynamoDB via Gateway Endpoint"
}

#############################
# Lambda Function Resources #
#############################

# Attach the DynamoDB access policy to lambda execution role
resource "aws_iam_role_policy_attachment" "game_word_lambda_table_access_attachment" {
  role       = local.main_lambda_exec_role_name
  policy_arn = module.game_words_table_access_policy.iam_policy_arn
}

# Attach Cloudwatch access policy to lambda execution role
resource "aws_iam_role_policy_attachment" "game_word_lambda_cloudwatch_access_attachment" {
  role       = local.main_lambda_exec_role_name
  policy_arn = module.game_words_lambda_cloudwatch_access_policy.iam_policy_arn
}

# Create Lambda function using the module and attach IAM role for execution
module "game_words_randomize_lambda" {
  source = "../../terraform-modules/lambda"

  lambda_function_name         = "${local.name_prefix}-func"
  lambda_handler               = "${var.python_source_code_file_name}.${var.python_function_name}"
  lambda_runtime               = "python${var.python_version_num}"
  lambda_memory_size           = var.python_exec_memory_size
  lambda_timeout               = var.python_exec_timeout
  lambda_iam_role_arn          = local.main_lambda_exec_role_arn
  lambda_s3_bucket_for_code    = var.python_s3_bucket
  lambda_s3_key_for_code       = var.python_s3_key
  lambda_environment_variables = merge(var.python_env_vars, { DYNAMODB_TABLE_NAME = module.game_words_table.table_name })
  lambda_tags                  = var.project_tags

  # For VPC Configuration
  lambda_subnet_ids         = [local.main_prv_subnet_id]
  lambda_security_group_ids = [aws_security_group.random_word_api_lambda_sg.id]

  depends_on = [
    module.game_words_lambda_cloudwatch_log_group,
    aws_iam_role_policy_attachment.game_word_lambda_cloudwatch_access_attachment
  ]
}

##################################
# REST method for RandomWord API #
##################################

# Get the "helloword" parent resource from the REST API
data "aws_api_gateway_resource" "main_resource" {
  rest_api_id = local.main_rest_api_id
  path        = "/helloword"
}

# Create the resource for the "getRandomWord" method
resource "aws_api_gateway_resource" "game_word_resource" {
  rest_api_id = local.main_rest_api_id
  parent_id   = data.aws_api_gateway_resource.main_resource.id
  path_part   = "getRandomWord"
}

# Create the "GET" method
resource "aws_api_gateway_method" "game_word_method" {
  rest_api_id   = local.main_rest_api_id
  resource_id   = aws_api_gateway_resource.game_word_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

# Create the integration for the "GET" method
resource "aws_api_gateway_integration" "game_word_lambda_integration" {
  rest_api_id             = local.main_rest_api_id
  resource_id             = aws_api_gateway_resource.game_word_resource.id
  http_method             = aws_api_gateway_method.game_word_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.game_words_randomize_lambda.lambda_arn}/invocations"
}

locals {
  current_account_info = "${var.aws_region}:${local.aws_account_id}"
  lambda_source_arn    = "arn:aws:execute-api:${local.current_account_info}:${local.main_rest_api_id}/*"
}

# Add lambda permission for the API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.game_words_randomize_lambda.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = local.lambda_source_arn

  # Add explicit dependency on API Gateway and Lambda resource
  depends_on = [
    aws_api_gateway_integration.game_word_lambda_integration,
    module.game_words_randomize_lambda
  ]
}

###########
# Outputs #
###########

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

# Output arn of Lambda function
output "lambda_function_arn" {
  description = "The ARN of the created lambda function"
  value       = module.game_words_randomize_lambda.lambda_arn
}
