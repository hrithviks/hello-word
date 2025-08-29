/*
Description : Outputs for API-Gateway REST API
*/

output "rest_api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "rest_api_name" {
  value = aws_api_gateway_rest_api.main.name
}

output "rest_api_endpoint" {
  value = aws_api_gateway_rest_api.main.endpoint_configuration
}
