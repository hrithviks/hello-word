/*
Author      : Hrithvik Saseendran
Description : Variable Declaration for DynamoDB
*/


variable "table_name" {
  description = "The name of the DynamoDB table."
  type        = string
}

variable "hash_key" {
  description = "The name of the Partition Key (HASH attribute)."
  type        = string
}

variable "range_key" {
  description = "The name of the Sort Key (RANGE attribute)."
  type        = string
}

variable "attributes" {
  description = "A list of attribute definitions for the primary key (and any indexes)."
  type = list(object({
    name = string
    type = string # S (String), N (Number), B (Binary)
  }))
}

variable "read_capacity" {
  description = "The number of read capacity units for the table."
  type        = number
  default     = 5 # Default to 5 RCUs
}

variable "write_capacity" {
  description = "The number of write capacity units for the table."
  type        = number
  default     = 5 # Default to 5 WCUs
}

variable "tags" {
  description = "A map of tags to assign to the table."
  type        = map(string)
  default     = {}
}
