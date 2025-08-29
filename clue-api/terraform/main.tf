/*
Project     : Hello Word Game
Service     : Clue API Service
Description : The terraform configuration for AWS resources for the Clue API
*/

# Setup Region
provider "aws" {
  region = var.aws_region
}

# Get Account Details
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
  main_lambda_exec_role_name = data.terraform_remote_state.main.outputs.main_lambda_exec_role_name
  main_lambda_exec_role_arn  = data.terraform_remote_state.main.outputs.main_lambda_exec_role_arn
  main_rest_api_id           = data.terraform_remote_state.main.outputs.main_api_gateway_id

  # Internal usage
  name_prefix    = lower("${var.project_name}-${var.service_name}")
  aws_account_id = data.aws_caller_identity.aws_resource_admin.account_id
}

###################################
# CloudWatch Log Group for Lambda #
###################################

# Create Cloudwatch log group for Lambda function
module "clue_lambda_cloudwatch_log_group" {
  source = "../../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = "/aws/lambda/${local.name_prefix}-func"
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group for Lambda function
module "clue_lambda_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = "${local.name_prefix}-lambda-cloudwatch-access-policy"
  iam_policy_description = "IAM policy for granting access to CloudWatch log group for the Clue API Lambda function"
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
        Resource = "${module.clue_lambda_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}

#############################
# Lambda Function Resources #
#############################

# Attach Cloudwatch access policy to lambda execution role
resource "aws_iam_role_policy_attachment" "clue_lambda_cloudwatch_access_attachment" {
  role       = local.main_lambda_exec_role_name
  policy_arn = module.clue_lambda_cloudwatch_access_policy.iam_policy_arn
}

# Create Lambda function using the module and attach IAM role for execution
module "clue_lambda" {
  source = "../../terraform-modules/lambda"

  lambda_function_name         = "${local.name_prefix}-func"
  lambda_handler               = "${var.python_source_code_file_name}.${var.python_function_name}"
  lambda_runtime               = "python${var.python_version_num}"
  lambda_memory_size           = var.python_exec_memory_size
  lambda_timeout               = var.python_exec_timeout
  lambda_iam_role_arn          = local.main_lambda_exec_role_arn
  lambda_s3_bucket_for_code    = var.python_s3_bucket
  lambda_s3_key_for_code       = var.python_s3_key
  lambda_environment_variables = merge(var.python_env_vars, { GEMINI_API_KEY = var.google_api_key })
  lambda_tags                  = var.project_tags

  ######################################################################################
  # Lambda resides in a public zone, as it doesnt need access to any private resources #
  ######################################################################################

  depends_on = [
    module.clue_lambda_cloudwatch_log_group,
    aws_iam_role_policy_attachment.clue_lambda_cloudwatch_access_attachment
  ]
}

############################
# REST method for Clue API #
############################

# Get the "helloword" parent resource from the REST API
data "aws_api_gateway_resource" "main_resource" {
  rest_api_id = local.main_rest_api_id
  path        = "/helloword"
}

# Create the resource for the "getRandomWord" method
resource "aws_api_gateway_resource" "clue_resource" {
  rest_api_id = local.main_rest_api_id
  parent_id   = data.aws_api_gateway_resource.main_resource.id
  path_part   = "getClue"
}

# Create the "GET" method
resource "aws_api_gateway_method" "clue_method" {
  rest_api_id   = local.main_rest_api_id
  resource_id   = aws_api_gateway_resource.clue_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

# Create the integration for the "GET" method
resource "aws_api_gateway_integration" "clue_lambda_integration" {
  rest_api_id             = local.main_rest_api_id
  resource_id             = aws_api_gateway_resource.clue_resource.id
  http_method             = aws_api_gateway_method.clue_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.clue_lambda.lambda_arn}/invocations"
}

locals {
  current_account_info = "${var.aws_region}:${local.aws_account_id}"
  lambda_source_arn    = "arn:aws:execute-api:${local.current_account_info}:${local.main_rest_api_id}/*"
}

# Add lambda permission for the API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = module.clue_lambda.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = local.lambda_source_arn

  # Add explicit dependency on API Gateway and Lambda resource
  depends_on = [
    aws_api_gateway_integration.clue_lambda_integration,
    module.clue_lambda
  ]
}

###########
# Outputs #
###########

# Output arn of Lambda function
output "lambda_function_arn" {
  description = "The ARN of the created lambda function"
  value       = module.clue_lambda.lambda_arn
}
