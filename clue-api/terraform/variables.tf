/*
Description : Variable Declaration for Clue API
*/

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
  default     = "Clue-API"
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_tags" {
  description = "The default tags for all the AWS resources in Guess-Word API Configuration"
  type        = map(any)
  default = {
    Project   = "HelloWord"
    Service   = "Clue-API"
    Terraform = true
  }
}

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
  default     = "3.13"
}

variable "python_source_code_file_name" {
  description = "Python source file (zipped) name used to configure the lambda function"
  type        = string
  default     = "get_clue"
}

variable "python_function_name" {
  description = "Function name in the python file to configure the lambda handler"
  type        = string
  default     = "lambda_handler"
}

variable "python_s3_bucket" {
  description = "S3 bucket name for hosting python code"
  type        = string
  default     = "hello-word-game"
}

variable "python_s3_key" {
  description = "Full path to python zip file on S3 bucket"
  type        = string
  default     = "clue-api/get_clue.py.zip"
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
  sensitive   = true
  type        = map(string)
  default = {
    MODE = "Test"
  }
}

variable "google_api_key" {
  description = "API Key for invoking the Generative AI API"
  sensitive   = true
  type        = string
}
