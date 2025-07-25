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
  default     = "HelloWord"
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

/*
VARIABLES FOR CLOUDWATCH
*/

variable "cloudwatch_retention_period" {
  description = "Retention period value for log group files in days"
  type        = number
  default     = 30
}

/*
VARIABLES FOR LAMBDA FUNCTION
*/

variable "python_version_num" {
  description = "Python version for lambda function"
  type        = string
  default     = "3.10"
}

variable "python_source_code_file_name" {
  description = "Python source file (zipped) name used to configure the lambda function"
  type        = string
  default     = "main"
}

variable "python_function_name" {
  description = "Function name in the python file to configure the lambda handler"
  type        = string
  default     = "lambda_handler"
}

variable "python_s3_bucket" {
  description = "S3 bucket name for hosting python code"
  type        = string
  default     = "hello-word-guess-api"
}

variable "python_s3_key" {
  description = "Full path to python zip file on S3 bucket"
  type        = string
  default     = "get_random_word.py.zip"
}

variable "python_exec_memory_size" {
  description = "Configured memory size for the lambda function"
  type        = number
  default     = 128
}

variable "python_exec_timeout" {
  description = "Configured timeout period for the function in seconds"
  type        = number
  default     = 30
}

variable "python_env_vars" {
  description = "Static environment variables for lambda function"
  type        = map(string)
  default = {
    DEFAULT_DIFFICULTY = "easy"
  }
}
