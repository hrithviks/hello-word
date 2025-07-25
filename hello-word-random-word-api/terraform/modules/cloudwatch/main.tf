/*
Author      : Hrithvik Saseendran
Description : Configuration for Cloudwatch Module
*/

resource "aws_cloudwatch_log_group" "main" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.cloudwatch_tags
}
