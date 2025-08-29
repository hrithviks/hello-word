/*
Description : Outputs from IAM Module
*/

output "iam_policy_arn" {
  description = "The ARN of the created IAM role."
  value       = aws_iam_policy.main.arn
}

output "iam_policy_name" {
  description = "The name of the created IAM role."
  value       = aws_iam_policy.main.name
}

output "iam_policy_id" {
  description = "The ID of the created IAM role."
  value       = aws_iam_policy.main.id
}
