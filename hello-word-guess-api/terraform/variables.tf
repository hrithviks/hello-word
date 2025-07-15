/*
Author      : Hrithvik Saseendran
Description : Variable Declaration for Guess Word API
*/

/*
VARIABLES FOR MAIN CONFIGURATION
*/

variable "environment" {
  description = "The deployment environment (e.g., dev, prod, staging)."
  type        = string
}

variable "project_name" {
  description = "The name of the project. Used as a prefix for resources."
  type        = string
  default     = "HelloWordGame"
}

variable "service_name" {
  description = "The name of the service in the project"
  type        = string
  default     = "GuessAPI"
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "ap-southeast-1" # Set your preferred default region
}

variable "project_tags" {
  description = "The default tags for all the AWS resources in Guess-Word API Configuration"
  type        = map(any)
  default = {
    Environment = "Dev"
    Project     = "HelloWord"
    Service     = "GuessAPI"
    Terraform   = true
  }
}

/*
VARIABLES FOR DYNAMO_DB TABLE
*/

variable "dynamodb_table_rcu" {
  description = "Read Capacity Units for the DynamoDB table."
  type        = number
  default     = 5
}

variable "dynamodb_table_wcu" {
  description = "Write Capacity Units for the DynamoDB table."
  type        = number
  default     = 5
}

variable "dynamodb_table_hash_key" {
  description = "The name of the Partition Key (HASH attribute) for the DynamoDB table."
  type        = string
  default     = "Category"
}

variable "dynamodb_table_range_key" {
  description = "The name of the Sort Key (RANGE attribute) for the DynamoDB table."
  type        = string
  default     = "Difficulty"
}

variable "dynamodb_table_attributes" {
  description = "List of attribute definitions for the DynamoDB table's primary key."
  type = list(object({
    name = string
    type = string
  }))
  default = [
    { name = "Category", type = "S" },
    { name = "Difficulty", type = "S" }
  ]
}
