/*
Project     : Hello Word Game
Service     : Backend Application
Description : The terraform configuration for AWS resources for the backend application
*/

########################
# Initialization Block #
########################

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
  main_vpc_id        = data.terraform_remote_state.main.outputs.main_vpc_id
  main_prv_subnet_id = data.terraform_remote_state.main.outputs.main_private_subnet_id
  main_pub_subnet_id = data.terraform_remote_state.main.outputs.main_public_subnet_id
  main_rest_api_name = data.terraform_remote_state.main.outputs.main_api_gateway_name
  main_rest_api_id   = data.terraform_remote_state.main.outputs.main_api_gateway_id

  # Internal usage
  name_prefix    = lower("${var.project_name}-${var.service_name}")
  aws_account_id = data.aws_caller_identity.aws_resource_admin.account_id
}

############################################
# Cloudwatch log group for the ECS Cluster #
############################################

# Create Cloudwatch log group for Lambda function
module "backend_ecs_cloudwatch_log_group" {
  source = "../../terraform-modules/cloudwatch/"

  cloudwatch_log_group_name    = "/ecs/${local.name_prefix}-ecs-log-group"
  cloudwatch_retention_in_days = var.cloudwatch_retention_period
  cloudwatch_tags              = var.project_tags
}

####################################
# SQS Queue for Message Processing #
####################################

################################
# Execution Role for ECS Tasks #
################################

# IAM execution role for ECS exec (resource)
module "backend_ecs_exec_role" {
  source = "../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${local.name_prefix}-ecs-exec-role"
  iam_role_description = "IAM role for backend ECS cluster to initialize tasks"
  iam_role_policy_json = local.ecs_role_json
  iam_role_tags        = merge(var.project_tags, { Name = "ECSBackendExecRole" })
}

# IAM execution role for ECS task (application)
module "backend_ecs_task_role" {
  source = "../terraform-modules/iam/roles/"

  # Assign values for module variables from input
  iam_role_name        = "${local.name_prefix}-ecs-task-role"
  iam_role_description = "IAM role for backend ECS tasks to access other resources"
  iam_role_policy_json = local.ecs_role_json
  iam_role_tags        = merge(var.project_tags, { Name = "ECSBackendTaskRole" })
}

###################################
# IAM Permission policies for ECS #
###################################

# Create policy for read-write access to Cloudwatch log group for ECS execution role
module "backend_ecs_exec_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = "${local.name_prefix}-ecs-exec-cloudwatch-access-policy"
  iam_policy_description = "IAM policy for granting access to CloudWatch log group for the ECS Execution Role"
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
        Resource = "${module.backend_ecs_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}

# Create policy for read-write access to Cloudwatch log group for ECS task role
module "backend_ecs_task_cloudwatch_access_policy" {
  source = "../../terraform-modules/iam/policies/"

  iam_policy_name        = "${local.name_prefix}-ecs-exec-cloudwatch-access-policy"
  iam_policy_description = "IAM policy for granting access to CloudWatch log group for the ECS Task Role"
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
        Resource = "${module.backend_ecs_cloudwatch_log_group.log_group_arn}:*"
      }
    ]
  })
  iam_policy_tags = var.project_tags
}
# API Gateway IAM

# SQS Queue IAM

# Attach the policy for cloudwatch to the execution role
resource "aws_iam_role_policy_attachment" "backend_ecs_exec_cloudwatch_policy_attachment" {
  role       = module.backend_ecs_exec_role.iam_role_name
  policy_arn = module.backend_ecs_exec_cloudwatch_access_policy.iam_policy_arn
}

# Attach the AWS managed policy to execute tasks to the execution role
resource "aws_iam_role_policy_attachment" "backend_ecs_exec_default_policy_attachment" {
  role       = module.backend_ecs_exec_role.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the policy for cloudwatch to the task role
resource "aws_iam_role_policy_attachment" "backend_ecs_task_cloudwatch_policy_attachment" {
  role       = module.backend_ecs_task_role.iam_role_name
  policy_arn = module.backend_ecs_task_cloudwatch_access_policy.iam_policy_arn
}

########################################## 
# Security Group for Backend ECS Cluster #
##########################################

resource "aws_security_group" "backend_ecs_sg" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for backend ECS cluster"
  vpc_id      = local.main_vpc_id
}

# Outbound traffic from ECS cluster to other services via VPC endpoints only
resource "aws_security_group_rule" "backend_ecs_sg_egress" {
  security_group_id = aws_security_group.backend_ecs_sg.id
  description       = "Outbound traffic rules from ECS cluster"
  from_port         = "443"
  to_port           = "443"
  protocol          = "HTTPS"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

# Inbound traffic to ECS cluster via ALB only
resource "aws_security_group_rule" "backend_ecs_sg_ingress" {
  security_group_id = aws_security_group.backend_ecs_sg.id
  description       = "Inbound traffic rules to ECS cluster"
  from_port         = "443"
  to_port           = "443"
  protocol          = "HTTPS"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

#####################################################
# Application Load Balancer for Backend Application #
#####################################################

#######################################################
# Interface end points for different backend services #
#######################################################

# API Gateway
# SQS
# Cloudwatch

#################
# ECS Resources #
#################

module "backend_ecs" {
  source = "../terraform-modules/ecs/"

  # ECS cluster configuration
  ecs_name = "${local.name_prefix}-ecs-cluster"
  ecs_tags = var.project_tags

  # ECS task configuration
  ecs_cpu                = 256
  ecs_memory             = 512
  ecs_execution_role_arn = module.backend_ecs_exec_role.iam_role_arn
  ecs_task_role_arn      = null

  # ECS cluster basic configuration
  ecs_cluster_name  = "${local.name_prefix}-ecs-cluster"
  ecs_task_name     = "${local.name_prefix}-ecs-task"
  ecs_service_name  = "${local.name_prefix}-ecs-service"
  ecs_launch_type   = "FARGATE"
  ecs_desired_count = 1

  # ECS Network configuration
  ecs_subnet_ids     = [local.main_prv_subnet_id]
  ecs_sg_ids         = [aws_security_group.backend_ecs_sg.id]
  ecs_public_ip_flag = false

  # ECS task configuration
  ecs_container_name  = "${local.name_prefix}-ecs-container"
  ecs_container_image = var.container_image
  ecs_container_port  = var.container_port
  ecs_host_port       = var.host_port

  # ECS task log configuration
  ecs_log_driver     = "awslogs"
  ecs_log_group_name = module.backend_ecs_cloudwatch_log_group.log_group_name
  ecs_log_region     = var.aws_region
  ecs_log_prefix     = "ecs-backend-app"
}


##############################
# Auto Scaling Group for ECS #
##############################
