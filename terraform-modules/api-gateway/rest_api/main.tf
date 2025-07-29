/*
Author      : Hrithvik Saseendran
Description : Main Configuration for API-Gateway REST API
*/

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = var.api_gateway_description
  body        = var.api_gateway_rest_api_body

  # Endpoint configuration for the API
  endpoint_configuration {
    types = [var.api_gateway_rest_endpoint_config]
  }
}
