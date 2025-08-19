output "main_vpc_name" {
  description = "The name of the main VPC"
  value       = aws_vpc.main_vpc.id
}

output "main_vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main_vpc.id
}

output "main_igw_id" {
  description = "The ID of the main internet gateway"
  value       = aws_internet_gateway.main_igw.id
}

output "main_public_subnet_id" {
  description = "The ID of the main public subnet"
  value       = aws_subnet.main_public_subnet.id
}

output "main_private_subnet_id" {
  description = "The ID of the main private subnet"
  value       = aws_subnet.main_private_subnet.id
}

output "main_public_rt_id" {
  description = "The ID of the main public route table"
  value       = aws_route_table.main_public_rt.id
}

output "main_private_rt_id" {
  description = "The ID of the main private route table"
  value       = aws_route_table.main_private_rt.id
}

output "main_lambda_sg_id" {
  description = "The ID of the main lambda security group"
  value       = aws_security_group.main_lambda_sg.id
}

output "main_lambda_sg_name" {
  description = "The name of the main lambda security group"
  value       = aws_security_group.main_lambda_sg.name
}

output "main_lambda_vpc_access_policy_arn" {
  description = "The ARN of the main lambda VPC access policy"
  value       = module.main_lambda_vpc_access_policy.iam_policy_arn
}

output "main_lambda_exec_role_arn" {
  description = "The ARN of the main lambda execution role"
  value       = module.main_lambda_exec_role.iam_role_arn
}
