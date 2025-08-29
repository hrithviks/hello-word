/*
Description : Outputs from DynamoDB Module
*/


output "table_name" {
  description = "The name of the created DynamoDB table."
  value       = aws_dynamodb_table.main.name
}

output "table_arn" {
  description = "The ARN of the created DynamoDB table."
  value       = aws_dynamodb_table.main.arn
}
