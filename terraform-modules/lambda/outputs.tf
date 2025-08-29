/*
Description : Outputs for Lambda functions
*/

output "lambda_arn" {
  description = "The ARN of the created Lambda function"
  value       = aws_lambda_function.main.arn
}
