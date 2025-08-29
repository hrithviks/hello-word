#############################
# Variables for Backend App #
#############################

variable "environment" {
  description = "The deployment environment (e.g., dev, prod, staging)."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project. Used as a prefix for resources."
  type        = string
  default     = "HelloWord"
}

variable "service_name" {
  description = "The name of the service in the project"
  type        = string
  default     = "Backend-App"
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_tags" {
  description = "The default tags for all the AWS resources in Random-Word API Configuration"
  type        = map(any)
  default = {
    Project   = "HelloWord"
    Service   = "Backend-App"
    Terraform = true
  }
}

/*
VARIABLES FOR CLOUDWATCH
*/

variable "cloudwatch_retention_period" {
  description = "Retention period value for log group files in days"
  type        = number
  default     = 30
}
