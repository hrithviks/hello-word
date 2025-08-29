/*
Project     : Hello Word Game
Service     : Main Configuration
Description : The terraform configuration for all the centrally managed resources for the project
*/

# Set region
provider "aws" {
  region = var.aws_region
}

# Get account details
data "aws_caller_identity" "aws_resource_admin" {}

locals {
  name_prefix = lower("${var.project_name}-${var.service_name}")
  vpc_tags    = merge(var.project_tags, { Section = "VPCSection" })
}

##########################################
# Core VPC configuration for the project #
##########################################

# VPC resource
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.vpc_tags, { Name = "${local.name_prefix}-vpc" })
}

# Internet gateway resource
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = "${local.name_prefix}-internetgateway" })
}

###############################
# Public subnet configuration #
###############################

# Public subnet resource
resource "aws_subnet" "main_public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.vpc_public_subnet_cidr
  availability_zone       = var.vpc_public_subnet_az
  map_public_ip_on_launch = true
  tags                    = merge(local.vpc_tags, { Name = "${local.name_prefix}-public-subnet" })
}

# Public route table resource
resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = "${local.name_prefix}-public-route-table" })
}

# Public route to internet gateway
resource "aws_route" "main_igw_route" {
  route_table_id         = aws_route_table.main_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "main_public_rt_assoc" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.main_public_rt.id
}

################################
# Private subnet configuration #
################################

# Private subnet resource
resource "aws_subnet" "main_private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.vpc_private_subnet_cidr
  availability_zone = var.vpc_private_subnet_az
  tags              = merge(local.vpc_tags, { Name = "${local.name_prefix}-private-subnet" })
}

# Private route table resource
resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = "${local.name_prefix}-private-route-table" })
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "main_private_rt_assoc" {
  subnet_id      = aws_subnet.main_private_subnet.id
  route_table_id = aws_route_table.main_private_rt.id
}

#########################
# Cloudwatch Log Groups #
#########################

module "main_api_gateway_cloudwatch_log_group" {
  source = "../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = "${local.name_prefix}/api-gateway-logs"
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

########################
# API Gateway Resource #
########################

module "main_rest_api" {
  source                           = "../terraform-modules/api-gateway/rest_api/"
  api_gateway_name                 = "hello-word-api-gateway"
  api_gateway_description          = "Main API gateway resource for the backend services"
  api_gateway_rest_endpoint_config = "REGIONAL"
  api_gateway_rest_api_body        = jsonencode(local.hello_word_openapi_specification_map)
}

################
# IAM policies #
################

# JSON definition for lambda function to manage VPC resources
locals {
  lambda_vpc_access_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
        Effect   = "Allow"
      },

      # Enforces policy only in the current VPC
      {
        Effect   = "Allow",
        Action   = "ec2:AttachNetworkInterface",
        Resource = "arn:aws:ec2:*:*:network-interface/*",
        Condition = {
          StringEquals = {
            "ec2:Vpc" : "arn:aws:ec2:*:*:vpc/${aws_vpc.main_vpc.id}"
          }
        }
      }
    ]
  })
}

# JSON definition for CloudWatch Log Group Access
locals {
  cloudwatch_log_group_access_json = jsonencode({
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
        Resource = "${module.main_api_gateway_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
}

# IAM policy for lambda function to manage VPC resources
module "main_lambda_vpc_access_policy" {
  source = "../terraform-modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = "${local.name_prefix}-lambda-vpc-access-policy"
  iam_policy_description = "IAM policy for Lambda to manage VPC resources"
  iam_policy_json        = local.lambda_vpc_access_policy_json
  iam_policy_tags        = merge(var.project_tags, { Name = "LambdaVPCAccessPolicy" })
}

# IAM execution role for lambda function
module "main_lambda_exec_role" {
  source = "../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${local.name_prefix}-lambda-exec-role"
  iam_role_description = "IAM role for lambda function to access other services"
  iam_role_policy_json = local.lambda_role_json
  iam_role_tags        = merge(var.project_tags, { Name = "LambdaExecRole" })
}

# Attach the policy to the execution role
resource "aws_iam_role_policy_attachment" "main_lambda_vpc_access_attachment" {
  role       = module.main_lambda_exec_role.iam_role_name
  policy_arn = module.main_lambda_vpc_access_policy.iam_policy_arn
}

# IAM policy for API Gateway
module "main_api_gateway_cloudwatch_policy" {
  source = "../terraform-modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = "${local.name_prefix}-apigateway-cloudwatch-access-policy"
  iam_policy_description = "IAM policy for API gateway to access cloudwatch logs"
  iam_policy_json        = local.cloudwatch_log_group_access_json
  iam_policy_tags        = merge(var.project_tags, { Name = "APIGatewayCloudWatchAccessPolicy" })
}

# IAM execution role for API Gateway
module "main_api_gateway_cloudwatch_role" {
  source = "../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${local.name_prefix}-apigateway-cloudwatch-role"
  iam_role_description = "IAM role for API gateway to access cloudwatch logs"
  iam_role_policy_json = local.api_gateway_role_json
  iam_role_tags        = merge(var.project_tags, { Name = "APIGatewayCloudWatchRole" })
}

# Attach the policy for cloudwatch to the execution role
resource "aws_iam_role_policy_attachment" "main_api_gateway_cloudwatch_policy_attachment" {
  role       = module.main_api_gateway_cloudwatch_role.iam_role_name
  policy_arn = module.main_api_gateway_cloudwatch_policy.iam_policy_arn
}

###################################
# S3 Buckets for various services #
###################################

locals {
  s3_buckets = [
    "random-word-api",
    "clue-api"
  ]
}

# Create S3 buckets for both API services
resource "aws_s3_bucket" "service_buckets" {

  for_each = toset(local.s3_buckets)
  bucket   = "${each.value}-bucket"
  tags     = merge(var.project_tags, { Name = "RandomWordAPIBucket" })
}

# Block public access to the buckets
resource "aws_s3_bucket_public_access_block" "block" {

  for_each                = aws_s3_bucket.service_buckets
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Set bucket policy to control access to the buckets
resource "aws_s3_bucket_policy" "service_bucket_policy" {

  for_each = aws_s3_bucket.service_buckets
  bucket   = each.value.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.aws_resource_admin.arn
        },
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ],
        Resource = [
          "${each.value.arn}",
          "${each.value.arn}/*"
        ]
      }
    ]
  })
}
