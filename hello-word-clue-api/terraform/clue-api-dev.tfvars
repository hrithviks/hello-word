/*
Author      : Hrithvik Saseendran
Description : Maintain variables for Guess Word API Infra Configuration
*/

# Environment variable for configuration
project_name = "HelloWord"
service_name = "Clue-API"

# Environment variables for DEV
environment = "dev"

# Variables for dynamoDB table
dynamodb_table_rcu       = 5
dynamodb_table_wcu       = 5
dynamodb_table_hash_key  = "clue_uuid"
dynamodb_table_range_key = "category"
dynamodb_table_attributes = [
  { name = "Clue_UUID", type = "S" },
  { name = "Category", type = "S" }
]

# Variables for lambda function
python_source_code_file_name = "get_random_word"
python_function_name         = "lambda_handler"
python_s3_bucket             = "hello-word-guess-api"
python_s3_key                = "get_random_word.py.zip"
