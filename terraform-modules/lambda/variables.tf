/*
Author      : Hrithvik Saseendran
Description : Variable Declaration for Lambda function
*/

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "lambda_handler" {
  description = "The function entrypoint in your code (e.g., index.lambda_handler)."
  type        = string
}

variable "lambda_runtime" {
  description = "The runtime identifier for the function's code (e.g., python3.9, nodejs16.x)."
  type        = string
}

variable "lambda_memory_size" {
  description = "The amount of memory (in MB) that the function has access to."
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "The amount of time (in seconds) that Lambda allows a function to run before stopping it."
  type        = number
  default     = 30
}

variable "lambda_environment_variables" {
  description = "A map of environment variables to pass to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "lambda_iam_role_arn" {
  description = "The ARN of the IAM role that Lambda assumes when it executes your function."
  type        = string
}

variable "lambda_s3_bucket_for_code" {
  description = "The name of the S3 bucket where the Lambda deployment package is stored."
  type        = string
}

variable "lambda_s3_key_for_code" {
  description = "The S3 key (path) of the Lambda deployment package within the bucket."
  type        = string
}

variable "lambda_tags" {
  description = "A map of tags to assign to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "lambda_create_timeout" {
  description = "The timeout value for lambda function before it fails during creation"
  type        = string
  default     = "2m"
}

variable "lambda_subnet_ids" {
  description = "The list of subnets for lambda function"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "The list of security groups for lambda function"
  type        = list(string)
  default     = []
}
