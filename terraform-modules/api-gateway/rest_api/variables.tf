/*
Description : Variable Declaration for API-Gateway REST API
*/

variable "api_gateway_name" {
  description = "The name of the REST API Gateway"
  type        = string
}

variable "api_gateway_description" {
  description = "The name of the REST API Gateway"
  type        = string
}

variable "api_gateway_rest_api_body" {
  description = "The body of REST API configuration with the standarized OpenAI format"
  type        = string
}

variable "api_gateway_rest_endpoint_config" {
  description = "The endpoint type required for the API Gateway"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "EDGE", "PRIVATE"], upper(var.api_gateway_rest_endpoint_config))
    error_message = "The gateway endpoint type must be one of REGIONAL, EDGE or PRIVATE"
  }
}
