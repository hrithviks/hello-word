/*
Description : Configuration for IAM Permissions and Roles
*/

resource "aws_iam_role" "main" {
  name                 = var.iam_role_name
  assume_role_policy   = var.iam_role_policy_json
  description          = var.iam_role_description
  max_session_duration = var.iam_role_max_session_duration
  tags                 = var.iam_role_tags
}
