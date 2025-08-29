/*
Description : Variable Declaration for IAM ROLES
*/

variable "iam_role_name" {
  description = "Name of IAM role to be created"
  type        = string
}

variable "iam_role_policy_json" {
  description = "The JSON policy for assuming the role"
  type        = string
}

variable "iam_role_description" {
  description = "A description of the IAM role."
  type        = string
  default     = "Generic IAM role managed by Guess Word API"
}

variable "iam_role_max_session_duration" {
  description = "Max session duration to assume the role's temporary credentials"
  type        = number
  default     = 3600 # 1 hour
}

variable "iam_role_tags" {
  description = "List of tags assigned to the IAM role"
  type        = map(string)
  default     = {}
}
