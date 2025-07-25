/*
Author      : Hrithvik Saseendran
Description : Outputs for API-Gateway REST API
*/

output "rest_api" {
  value = aws_api_gateway_rest_api.main
}
