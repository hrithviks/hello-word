/*
For Basic Setup
*/

variable "aws_region" {
  type        = string
  description = "The AWS region for provisioning resources centrally"
  default     = "ap-southeast-1"
}

variable "aws_azs" {
  type    = list(string)
  default = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "HelloWord"
}

variable "service_name" {
  type        = string
  description = "The name of the main service"
  default     = "RootService"
}

variable "project_tags" {
  type        = map(any)
  description = "The default tags for all the AWS resources managed centrally"
  default = {
    Project = "HelloWord"
    Service = "MainService"
  }
}

/*
For VPC Section
*/

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnet_cidr" {
  type        = string
  description = "The cidr block for public subnet."
  default     = "10.0.1.0/24"
}

variable "vpc_public_subnet_az" {
  type        = string
  description = "The availability zone for the public subnet."
  default     = "ap-southeast-1a"
}

variable "vpc_private_subnet_cidr" {
  type        = string
  description = "The CIDR blocks for the private subnets"
  default     = "10.0.2.0/24"
}

variable "vpc_private_subnet_az" {
  type        = string
  description = "The availability zone for the public subnet."
  default     = "ap-southeast-1b"
}
