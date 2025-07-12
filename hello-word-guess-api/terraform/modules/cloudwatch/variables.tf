/*
Author      : Hrithvik Saseendran
Description : Variable Declaration for Cloudwatch Module
*/

variable "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group."
  type        = string
}

variable "cloudwatch_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group."
  type        = number
  default     = 7 # Default to 7 days retention
}

variable "cloudwatch_tags" {
  description = "A map of tags to assign to the CloudWatch Log Group."
  type        = map(string)
  default     = {}
}
