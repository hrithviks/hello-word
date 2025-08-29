/*
Description : Configuration for IAM Permissions and Roles
*/

resource "aws_iam_policy" "main" {
  name        = var.iam_policy_name
  description = var.iam_policy_description
  policy      = var.iam_policy_json
}
