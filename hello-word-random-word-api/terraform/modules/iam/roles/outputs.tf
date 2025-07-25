/*
Author      : Hrithvik Saseendran
Description : Outputs from IAM Module
*/

output "iam_role_arn" {
  description = "The ARN of the created IAM role."
  value       = aws_iam_role.main.arn
}

output "iam_role_name" {
  description = "The name of the created IAM role."
  value       = aws_iam_role.main.name
}

output "iam_role_id" {
  description = "The ID of the created IAM role."
  value       = aws_iam_role.main.id
}
