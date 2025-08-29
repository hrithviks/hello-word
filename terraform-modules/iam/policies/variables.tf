/*
Description : Variable Declaration for IAM Permission Policies
*/

variable "iam_policy_name" {
  description = "Name of IAM policy to be created"
  type        = string
}

variable "iam_policy_description" {
  description = "A description of IAM policy"
  type        = string
}

variable "iam_policy_json" {
  description = "The JSON policy for assuming the role"
  type        = string
}

variable "iam_policy_tags" {
  description = "List of tags assigned to the IAM role"
  type        = map(string)
  default     = {}
}
