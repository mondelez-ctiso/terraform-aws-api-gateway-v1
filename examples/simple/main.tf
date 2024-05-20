###########################
# Supporting resources
#######RIP####################

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0.0"

  function_name = "hello-world-lambda"
  description   = "Hello-World lambda function"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  publish = true

  create_package = true

  source_path = "../test_infrastructure/src_lambda"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service = "apigateway"
      arn     = module.api_gateway.rest_api_execution_arn
    }
  }

  layers = ["arn:aws:lambda:us-east-2:017000801446:layer:AWSLambdaPowertoolsPythonV2:46"]
}

resource "aws_cloudwatch_log_group" "api_gw_log_group" {
  name              = "/aws/apigateway/simple-test-api-logs"
  retention_in_days = 7
}

module "api_gateway" {
  source = "../..//."

  api_gateway = {
    name                     = "simple-test-api-gateway"
    description              = "The test api-gateway"
    minimum_compression_size = 0
    api_key_source           = "HEADER"
    endpoint_configuration = {
      types = ["REGIONAL"]
    }
    api_gateway_client_cert_enabled = false
  }

  api_gateway_stages = [
    {
      stage_name        = "prod"
      stage_description = "The stage defined for prod, tied to the default deployment."
      access_log_settings = [{
        destination_arn = aws_cloudwatch_log_group.api_gw_log_group.arn
        format          = "{ \"requestId\":\"$context.requestId\", \"extendedRequestId\":\"$context.extendedRequestId\",\"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"user\":\"$context.identity.user\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\", \"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\", \"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
      }]
    },
    {
      stage_name        = "staging"
      stage_description = "The stage defined for staging"
      access_log_settings = [{
        destination_arn = aws_cloudwatch_log_group.api_gw_log_group.arn
        format          = "{ \"requestId\":\"$context.requestId\", \"extendedRequestId\":\"$context.extendedRequestId\",\"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"user\":\"$context.identity.user\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\", \"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\", \"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\" }"
      }]
    }
  ]
  api_gateway_methods = [
    {
      resource_path = "myPath"

      api_method = {
        authorization = "NONE"
        integration = {
          uri = module.lambda_function.lambda_function_invoke_arn
        }
        http_method = "GET"
      }
    },
    {
      resource_path = "myPath"

      api_method = {
        # settings = {
        #   metrics_enabled = true
        # }
        authorization = "NONE"
        integration = {
          uri = module.lambda_function.lambda_function_invoke_arn
        }
        http_method = "POST"
      }
    },
    {
      resource_path = "mySecondPath"

      api_method = {
        settings = {
          metrics_enabled = true
        }
        authorization = "NONE"
        integration = {
          uri = module.lambda_function.lambda_function_invoke_arn
        }
        http_method = "GET"
      }
    }
  ]
}
