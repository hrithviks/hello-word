/*
Project.    : Hello Word Game
Service.    : Central Configuration
Description : The terraform configuration for all the centrally managed resources for the project
*/

provider "aws" {
  region = var.aws_region
}

##########################################
# Core VPC configuration for the project #
##########################################

locals {
  name_prefix = lower("${var.project_name}-${var.service_name}")
  vpc_tags = merge(var.project_tags,
    {
      Section = "VPCSection"
  })
}

# VPC resource
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-VPC") })
}

# Internet gateway resource
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-InternetGateway") })
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
  tags                    = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-PublicSubnet") })
}

# Public route table resource
resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-PublicRouteTable") })
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
  tags              = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-PrivateSubnet") })
}

# Private route table resource
resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = merge(local.vpc_tags, { Name = lower("${local.name_prefix}-PrivateRouteTable") })
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "main_private_rt_assoc" {
  subnet_id      = aws_subnet.main_private_subnet.id
  route_table_id = aws_route_table.main_private_rt.id
}

##############################################
# VPC end points for internal communications #
##############################################

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "main_dynamodb_endpoint" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [
    aws_route_table.main_private_rt.id,
    aws_route_table.main_public_rt.id
  ]
  tags = merge(local.vpc_tags, { Name = "DynamoDB VPC Gateway Endpoint" })
}

##########################
# Security Groups in VPC #
##########################

# Security group for lambda functions
resource "aws_security_group" "main_lambda_sg" {
  name        = lower("${local.name_prefix}-LambdaSecurityGroup")
  description = "Security group for lambda functions"
  vpc_id      = aws_vpc.main_vpc.id
}

# Security group for outbound access to DynamoDB via Gateway Endpoint
resource "aws_security_group_rule" "main_lambda_sg_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.main_lambda_sg.id
  prefix_list_ids   = [aws_vpc_endpoint.main_dynamodb_endpoint.prefix_list_id]
  description       = "Allow outbound access to DynamoDB via Gateway Endpoint"
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

# JSON definition for lambda execution role
locals {
  lambda_role_json = jsonencode({
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
}

# Generate IAM policy for lambda function to manage VPC resources
module "main_lambda_vpc_access_policy" {
  source = "../terraform-modules/iam/policies/"

  # Assign values for module variables from input
  iam_policy_name        = lower("${local.name_prefix}-Lambda-VPC-Access-Policy")
  iam_policy_description = "IAM policy for Lambda to manage VPC resources"
  iam_policy_json        = local.lambda_vpc_access_policy_json
  iam_policy_tags        = merge(var.project_tags, { Name = "LambdaVPCAccessPolicy" })
}

# IAM execution role for lambda function
module "main_lambda_exec_role" {
  source = "../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = lower("${local.name_prefix}-Lambda-Exec-Role")
  iam_role_description = "IAM role for lambda function to access other services"
  iam_role_policy_json = local.lambda_role_json
  iam_role_tags        = merge(var.project_tags, { Name = "LambdaExecRole" })
}

# Attach the policy to the execution role
resource "aws_iam_role_policy_attachment" "main_lambda_table_access_attachment" {
  role       = module.main_lambda_exec_role.iam_role_name
  policy_arn = module.main_lambda_vpc_access_policy.iam_policy_arn
}


###################################
# S3 Buckets for various services #
###################################

# S3 bucket for clue-api service - for backend and lambda code

# S3 bucket for random-word-api service backend - for backend and lambda code

# S3 bucket for static website for the front end system

# S3 Gateway End Point
/*
 - Used by private lambda functions to deploy the code
 - Common end point for all the lambda functions
*/

# DynamoDB Gateway End Point
/*
 - Used by lambda function to get data
 - Common end point for all the lambda functions
*/

# API Gateway Interface End Point
/*
- Used by ECS/EKS to query invoke the lambda functions
*/

# KMS Interface End Point

# Secrets Manager Interface End Point

# Lambda Interface End Point
/*
 - Used by API Gateway to invoke the functions
*/

# SQS Interface End Point
