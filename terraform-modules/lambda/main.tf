/*
Author      : Hrithvik Saseendran
Description : Configuration for Lambda functions
*/

resource "aws_lambda_function" "main" {
  function_name    = var.lambda_function_name
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  role             = var.lambda_iam_role_arn
  source_code_hash = data.aws_s3_object.lambda_code.etag

  s3_bucket = var.lambda_s3_bucket_for_code
  s3_key    = var.lambda_s3_key_for_code

  environment {
    variables = var.lambda_environment_variables
  }

  tags = var.lambda_tags
}

data "aws_s3_object" "lambda_code" {
  bucket = var.lambda_s3_bucket_for_code
  key    = var.lambda_s3_key_for_code
}
