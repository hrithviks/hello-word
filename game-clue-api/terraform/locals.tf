/*
Author      : Hrithvik Saseendran
Description : Locals for the main terraform configuration
*/

locals {

  /*
  openAI specification, used to build the random word API
  */
  random_word_openapi_specification_map = {
    openapi = "3.0.1"
    info = {
      title   = "Hello Word API Template"
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
        description = "Operations parent resource. Direct access is forbidden."
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
      "/helloword/getRandomWord" = {
        get = {
          summary     = "API to get a random word."
          description = "Invokes lambda function to get a random word based on query parameters. The request is authenticated by AWS IAM."
          security = [
            {
              aws_iam = []
            }
          ]
          x-amazon-apigateway-integration = {
            uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.game_words_randomize_lambda.lambda_arn}/invocations"
            type                = "aws_proxy"
            httpMethod          = "POST"
            passthroughBehavior = "when_no_match"
            responses           = {}
            requestParameters   = {}
            requestTemplates    = {}
            authorizationType   = "AWS_IAM"
          }
          responses = {
            "200" = {
              description = "Success"
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
}
