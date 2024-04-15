###########################
# Supporting resources
###########################
# This needs Python on the container... RIP

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0.0"

  function_name = "hello-world-lambda"
  description   = "Hello-World lambda function"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"

  publish = true

  create_package = true

  source_path = "../test_infrastructure/src_lambda"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service = "apigateway"
      arn     = module.api_gateway.rest_api_execution_arn
    }
  }
}

module "api_gateway" {
  source = "../..//."

  api_gateway = {
    name           = "simple-test-api-gateway"
    custom_domain  = "api-gateway-v1.test.cloud.mdlz.com"
    hosted_zone_id = "test.cloud.mdlz.com"
    acm_cert_arn   = null
  }

  api_gateway_stages = [
    {
      stage_name        = "main"
      stage_description = "The stage defined for main, tied to the default deployment."
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
        authorization = "NONE"
        integration = {
          uri = module.lambda_function.lambda_function_invoke_arn
        }
        http_method = "GET"
      }
    }
  ]
}
