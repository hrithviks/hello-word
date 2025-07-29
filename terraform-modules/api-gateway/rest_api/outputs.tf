/*
Author      : Hrithvik Saseendran
Description : Outputs for API-Gateway REST API
*/

output "rest_api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "rest_api_endpoint" {
  value = aws_api_gateway_rest_api.main.endpoint_configuration
}
