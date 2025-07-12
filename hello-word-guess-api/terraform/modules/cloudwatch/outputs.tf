/*
Author      : Hrithvik Saseendran
Description : Outputs from Cloudwatch Module
*/

output "log_group_arn" {
  description = "The ARN of the created CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.main.arn
}

output "log_group_name" {
  description = "The name of the created CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.main.name
}
