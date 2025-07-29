# This space documents all the features and technical specifications of terraform-modules

This document provides an overview of the reusable Terraform modules created for this project. Each module is designed to be a self-contained unit for creating a specific piece of AWS infrastructure.

## Lambda Function

This module creates an AWS Lambda function. It takes the function's code from an S3 bucket and configures its runtime, handler, memory, timeout, and execution role.

### Variables

| Name                           | Description                                            | Type          |
| :----------------------------- | :----------------------------------------------------- | :------------ |
| `lambda_function_name`         | The name of the Lambda function.                       | `string`      |
| `lambda_handler`               | The function within your code that Lambda calls.       | `string`      |
| `lambda_runtime`               | The identifier of the function's runtime.              | `string`      |
| `lambda_memory_size`           | The amount of memory that your function has access to. | `number`      |
| `lambda_timeout`               | The amount of time that Lambda allows a function to run.| `number`      |
| `lambda_iam_role_arn`          | The ARN of the IAM role that Lambda assumes.           | `string`      |
| `lambda_s3_bucket_for_code`    | The S3 bucket where the Lambda function code is stored.| `string`      |
| `lambda_s3_key_for_code`       | The S3 key for the Lambda function code zip file.      | `string`      |
| `lambda_environment_variables` | Environment variables for the Lambda function.         | `map(string)` |
| `lambda_tags`                  | A map of tags to assign to the Lambda function.        | `map(string)` |

### Outputs

| Name         | Description                        |
| ------------ | ---------------------------------- |
| `lambda_arn` | The ARN of the Lambda function.    |
| `lambda_name`| The name of the Lambda function.   |

## DynamoDB

This module creates an Amazon DynamoDB table with a specified hash key, range key, attributes, and provisioned throughput capacity.

### Variables

| Name                   | Description                                             | Type                |
| ---------------------- | ------------------------------------------------------- | ------------------- |
| `table_name`           | The name of the DynamoDB table.                         | `string`            |
| `hash_key`             | The name of the hash key attribute.                     | `string`            |
| `range_key`            | The name of the range key attribute.                    | `string`            |
| `attributes`           | A list of attribute definitions for the table.          | `list(object)`      |
| `read_capacity`        | The provisioned read capacity units.                    | `number`            |
| `write_capacity`       | The provisioned write capacity units.                   | `number`            |
| `tags`                 | A map of tags to assign to the DynamoDB table.          | `map(string)`       |

### Outputs

| Name         | Description                       |
| ------------ | --------------------------------- |
| `table_name` | The name of the DynamoDB table.   |
| `table_arn`  | The ARN of the DynamoDB table.    |
| `table_id`   | The ID of the DynamoDB table.     |

## API Gateway

This module creates an Amazon API Gateway REST API from an OpenAPI (Swagger) specification.

### Variables

| Name                             | Description                                                              | Type     |
| -------------------------------- | ------------------------------------------------------------------------ | -------- |
| `api_gateway_name`               | The name of the API Gateway.                                             | `string` |
| `api_gateway_description`        | The description for the API Gateway.                                     | `string` |
| `api_gateway_rest_endpoint_config` | The endpoint configuration of the API Gateway. (e.g., `REGIONAL`)      | `string` |
| `api_gateway_rest_api_body`      | An OpenAPI specification JSON string that defines the REST API.          | `string` |
| `tags`                           | A map of tags to assign to the API Gateway.                              | `map(string)` |

### Outputs

| Name            | Description                                |
| --------------- | ------------------------------------------ |
| `rest_api_id`   | The ID of the created REST API.            |
| `rest_api_arn`  | The ARN of the created REST API.           |
| `execution_url` | The execution URL of the deployed API.     |

## CloudWatch

This module creates an Amazon CloudWatch Log Group to store logs from other AWS services.

### Variables

| Name                           | Description                                             | Type          |
| ------------------------------ | ------------------------------------------------------- | ------------- |
| `cloudwatch_log_group_name`    | The name of the CloudWatch Log Group.                   | `string`      |
| `cloudwatch_retention_in_days` | The number of days to retain log events.                | `number`      |
| `cloudwatch_tags`              | A map of tags to assign to the Log Group.               | `map(string)` |

### Outputs

| Name            | Description                             |
| --------------- | --------------------------------------- |
| `log_group_name`| The name of the CloudWatch Log Group.   |
| `log_group_arn` | The ARN of the CloudWatch Log Group.    |

## IAM

This section covers modules for managing AWS Identity and Access Management (IAM) resources.

### Roles

This module creates an IAM Role with a specified assume role policy. This role can then be assumed by AWS services or other entities.

#### Variables

| Name                            | Description                                                          | Type          |
| ------------------------------- | -------------------------------------------------------------------- | ------------- |
| `iam_role_name`                 | Name of IAM role to be created.                                      | `string`      |
| `iam_role_policy_json`          | The JSON policy for assuming the role.                               | `string`      |
| `iam_role_description`          | A description of the IAM role.                                       | `string`      |
| `iam_role_max_session_duration` | Max session duration to assume the role's temporary credentials.     | `number`      |
| `iam_role_tags`                 | List of tags assigned to the IAM role.                               | `map(string)` |

#### Outputs

| Name            | Description                       |
| --------------- | --------------------------------- |
| `iam_role_name` | The name of the created IAM role. |
| `iam_role_arn`  | The ARN of the created IAM role.  |

### Policies

This module creates an IAM Policy from a JSON document. This policy can then be attached to IAM roles, users, or groups.

#### Variables

| Name                     | Description                               | Type          |
| ------------------------ | ----------------------------------------- | ------------- |
| `iam_policy_name`        | The name of the IAM policy.               | `string`      |
| `iam_policy_description` | A description for the IAM policy.         | `string`      |
| `iam_policy_json`        | The policy document in JSON format.       | `string`      |
| `iam_policy_tags`        | A map of tags to assign to the IAM policy.| `map(string)` |

#### Outputs

| Name             | Description                        |
| ---------------- | ---------------------------------- |
| `iam_policy_arn` | The ARN of the created IAM policy. |
