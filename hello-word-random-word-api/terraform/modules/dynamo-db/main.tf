/*
Author      : Hrithvik Saseendran
Description : Configuration for DynamoDb
*/

resource "aws_dynamodb_table" "main" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = var.hash_key
  range_key      = var.range_key

  # Define the attributes for primary key
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Set Point in time recovery to disabled
  point_in_time_recovery {
    enabled = false
  }

  # Use AWS owned keys (default option for encryption)
  server_side_encryption {
    enabled = false
  }

  tags = var.tags
}
