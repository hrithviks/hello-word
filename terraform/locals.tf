#################################
# Locals for main configuration #
#################################

locals {

  # Open API Specification for API Gateway
  hello_word_openapi_specification_map = {
    openapi = "3.0.1"
    info = {
      title   = "Hello Word Game API Template"
      version = "1.0"
    }
    paths = {
      "/" = {
        get = {
          summary     = "Forbidden Access to root."
          description = "Returns a 403 Forbidden response. No direct access to root resource."
          security    = [{}]
          x-amazon-apigateway-integration = {
            type                = "mock"
            passthroughBehavior = "when_no_match"
            requestTemplates = {
              "application/json" = jsonencode({ "statusCode" = 403 })
            }
            responses = {
              "403" = {
                statusCode = "403"
                responseTemplates = {
                  "application/json" = jsonencode({ "message" = "Forbidden operation on the resource" })
                }
              }
            }
          }
          responses = {
            "403" = {
              description = "Forbidden operation on root resource."
            }
          }
        }
      }
      "/helloword" = {
        description = "Parent resource. Direct access is forbidden."
        get = {
          summary     = "Forbidden Access"
          description = "Returns a 403 Forbidden response."
          security    = [{}]
          x-amazon-apigateway-integration = {
            type                = "mock"
            passthroughBehavior = "when_no_match"
            requestTemplates = {
              "application/json" = jsonencode({ "statusCode" = 403 })
            }
            responses = {
              "403" = {
                statusCode = "403"
                responseTemplates = {
                  "application/json" = jsonencode({ "message" = "Forbidden operation on the resource" })
                }
              }
            }
          }
          responses = {
            "403" = {
              description = "Forbidden operation on parent resource."
            }
          }
        }
      }
    }
    components = {
      securitySchemes = {
        aws_iam = {
          type                         = "apiKey"
          name                         = "Authorization"
          in                           = "header"
          x-amazon-apigateway-authtype = "awsSigv4"
        }
      }
    }
  }

  # JSON definition for API gateway execution role
  api_gateway_role_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })

  # JSON definition for lambda execution role
  lambda_role_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })
}
